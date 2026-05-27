import hashlib
import logging
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.config import settings
from .cache_service import CacheService
from ..schemas.chat import Message
from ..db.repositories.conversation_repository import ConversationRepository
from ..tasks.conversation_tasks import generate_summary_and_topics_task

logger = logging.getLogger(__name__)

MIKU_SYSTEM_PROMPT = (
    "Sei Hatsune Miku, un'assistente virtuale e programmatrice allegra, amichevole e gentile. "
    "Rispondi SEMPRE in italiano, usando un tono naturale, educato ed entusiasta. "
    "Poiché le tue risposte verranno lette a voce alta via sintesi vocale (TTS), segui RIGIDAMENTE queste regole di formattazione:\n"
    "1. Rispondi con frasi brevi, discorsive e semplici (massimo 2-3 frasi per risposta).\n"
    "2. NON utilizzare MAI simboli markdown come asterischi per descrivere azioni (es. evita *waving*, *giggles*, *sorride*).\n"
    "3. NON utilizzare elenchi puntati, tabelle, blocchi di codice complessi o elenchi numerati.\n"
    "4. Mantieni la risposta pulita, usando solo testo semplice e punteggiatura standard."
)

class ConversationMemoryService:
    """
    Servizio per la gestione intelligente della memoria conversazionale.
    Salva la cronologia in PostgreSQL come fonte di verità, e utilizza Redis
    come cache veloce. Ottimizza la finestra di contesto inviando solo gli
    ultimi N messaggi recenti arricchiti da un riassunto dello storico.
    """
    def __init__(self):
        self._local_history: Dict[str, List[Dict[str, str]]] = {}
        self._db_offline: bool = False
        self._last_db_attempt: float = 0.0
        self._db_retry_interval: float = 30.0 # Riprova al massimo ogni 30 secondi

    @property
    def db_offline(self) -> bool:
        import time
        now = time.time()
        # Se siamo offline ma è passato il cooldown, resettiamo temporaneamente per riprovare
        if self._db_offline and (now - self._last_db_attempt >= self._db_retry_interval):
            logger.info("[DATABASE] Fine periodo di cooldown. Si tenterà una nuova connessione a PostgreSQL.")
            self._db_offline = False
        return self._db_offline

    def add_local_message(self, conversation_id: str, role: str, content: str):
        """Salva un messaggio nella cache locale in memoria (usato come fallback)."""
        if conversation_id not in self._local_history:
            self._local_history[conversation_id] = []
        self._local_history[conversation_id].append({"role": role, "content": content})
        logger.debug(f"[MEMORY-FALLBACK] Aggiunto messaggio in memoria locale per {conversation_id}: {role}")

    def get_conversation_id(self, messages: List[Message]) -> str:
        """
        Genera un ID conversazione univoco e deterministico calcolando
        l'MD5 del testo del primo messaggio.
        """
        if not messages:
            return "default_conv"
        
        first_message_content = messages[0].content
        return hashlib.md5(first_message_content.encode('utf-8')).hexdigest()

    async def optimize_history(
        self,
        db: AsyncSession,
        messages: List[Message],
        conversation_id: str,
        model: str
    ) -> List[Dict[str, str]]:
        """
        Sincronizza i nuovi messaggi con PostgreSQL, ottimizza la cronologia
        lasciando solo gli ultimi messaggi recenti e prependendo il riassunto
        passato caricato da Redis o PostgreSQL (con ripopolamento cache).
        Suscita infine l'aggiornamento in background della memoria tramite Celery.
        """
        max_messages = getattr(settings, "CONVERSATION_MEMORY_MAX_MESSAGES", 8)
        import time
        
        # Controlla lo stato della connessione al database
        use_db = not self.db_offline
        db_messages = []
        
        if use_db:
            try:
                # 1. Recupera o crea la conversazione su DB per garantire che esista
                await ConversationRepository.get_or_create_conversation(db, conversation_id, active_model=model)

                # 2. Sincronizza i messaggi inviati dal client con il database PostgreSQL
                db_messages = await ConversationRepository.get_messages(db, conversation_id)
                db_len = len(db_messages)
                req_len = len(messages)
                
                if req_len > db_len:
                    # Aggiunge solo i messaggi mancanti nel database
                    missing_messages = messages[db_len:]
                    for msg in missing_messages:
                        await ConversationRepository.add_message(
                            db,
                            conversation_id=conversation_id,
                            role=msg.role,
                            content=msg.content
                        )
                    # Ricarica la cronologia aggiornata da DB
                    db_messages = await ConversationRepository.get_messages(db, conversation_id)
            except Exception as e:
                logger.warning(f"[DATABASE] Connessione a PostgreSQL fallita ({e}). Passaggio alla modalità in-memory temporanea.")
                self._db_offline = True
                self._last_db_attempt = time.time()
                use_db = False

        if not use_db:
            # Sincronizza lo stato in memoria locale
            if conversation_id not in self._local_history:
                self._local_history[conversation_id] = []
            
            local_list = self._local_history[conversation_id]
            local_len = len(local_list)
            req_len = len(messages)
            
            # Se la richiesta ha nuovi messaggi rispetto alla cronologia locale, li aggiungiamo
            if req_len > local_len:
                missing_messages = messages[local_len:]
                for msg in missing_messages:
                    local_list.append({"role": msg.role, "content": msg.content})
            
            ollama_messages = local_list
        else:
            # Formatta i messaggi del DB per l'invio a Ollama
            ollama_messages = [
                {"role": msg.role, "content": msg.content}
                for msg in db_messages
            ]
        
        # Se la conversazione è corta, la inviamo così com'è prependendo il system prompt
        if len(ollama_messages) <= max_messages:
            if len(ollama_messages) >= 3 and use_db:
                # Pre-warm del summary in background (solo se il DB è online)
                self._trigger_summary_update(conversation_id, model)
            return [{"role": "system", "content": MIKU_SYSTEM_PROMPT}] + ollama_messages

        # Se supera la soglia, separiamo gli ultimi max_messages
        recent_messages = ollama_messages[-max_messages:]
        
        # Prova a leggere il summary da Redis cache
        summary_key = f"conv:{conversation_id}:summary"
        topics_key = f"conv:{conversation_id}:topics"
        
        summary = CacheService.get(summary_key)
        topics = CacheService.get(topics_key)
        
        # Se c'è un cache miss su Redis, proviamo a leggere da PostgreSQL
        if not summary and use_db:
            try:
                logger.info(f"[MEMORY] Cache miss per {conversation_id}. Tento lettura da PostgreSQL...")
                summary_obj = await ConversationRepository.get_summary(db, conversation_id)
                topics_obj = await ConversationRepository.get_topics(db, conversation_id)
                
                if summary_obj:
                    summary = summary_obj.summary
                    topics = ", ".join([t.topic for t in topics_obj]) if topics_obj else ""
                    
                    # Ripopola la cache Redis per la prossima lettura
                    CacheService.set(summary_key, summary, ttl=604800)
                    CacheService.set(topics_key, topics, ttl=604800)
                    logger.info(f"[MEMORY] Cache Redis ripopolata per {conversation_id}.")
            except Exception as e:
                logger.warning(f"[DATABASE] Impossibile leggere il summary da PostgreSQL ({e}). Bypass per questa chiamata.")
        
        optimized_list = [{"role": "system", "content": MIKU_SYSTEM_PROMPT}]

        if summary:
            # Inietta il riassunto come contesto di sistema
            topics_info = f" (Argomenti trattati: {topics})" if topics else ""
            system_context_msg = (
                f"[CONTESTO PRECEDENTE]\n"
                f"La conversazione passata è stata riassunta come segue:\n"
                f"\"{summary}\"{topics_info}\n"
                f"Usa queste informazioni se l'utente vi fa riferimento."
            )
            optimized_list.append({"role": "system", "content": system_context_msg})
        else:
            # Se nessun summary è disponibile su DB/Cache, inviamo tutto il contesto storico per non perderlo
            logger.info(f"[MEMORY] Nessun summary trovato su DB/cache per {conversation_id}. Invio history completa.")
            if use_db:
                self._trigger_summary_update(conversation_id, model)
            return [{"role": "system", "content": MIKU_SYSTEM_PROMPT}] + ollama_messages

        # Aggiunge i messaggi della finestra recente
        optimized_list.extend(recent_messages)
        
        # Accoda il calcolo asincrono del nuovo summary in background
        if use_db:
            self._trigger_summary_update(conversation_id, model)
        
        return optimized_list

    def _trigger_summary_update(self, conversation_id: str, model: str):
        """
        Accoda il task Celery passandogli solo gli ID necessari.
        Il worker leggerà i messaggi direttamente da PostgreSQL.
        """
        try:
            generate_summary_and_topics_task.delay(conversation_id, model)
            logger.info(f"[MEMORY] Accodato task Celery per aggiornamento memoria della conversazione: {conversation_id}")
        except Exception as e:
            logger.warning(f"[MEMORY] Impossibile avviare il task Celery ({e}). Procedo in degradazione controllata.")

# Singleton
conversation_memory_service = ConversationMemoryService()
