import hashlib
import logging
from typing import List, Dict, Any
from ..core.config import settings
from .cache_service import CacheService
from ..schemas.chat import Message
from ..tasks.conversation_tasks import generate_summary_and_topics_task

logger = logging.getLogger(__name__)

class ConversationMemoryService:
    """
    Servizio per la gestione intelligente della memoria conversazionale.
    Mantiene il contesto leggero inviando solo gli ultimi N messaggi recenti
    e vi affianca un riassunto dei messaggi passati e dei topic principali,
    aggiornati asincronamente tramite Celery.
    """

    def get_conversation_id(self, messages: List[Message]) -> str:
        """
        Genera un ID conversazione univoco e deterministico calcolando
        l'MD5 del testo del primo messaggio (generalmente fisso in una sessione di chat).
        Permette la compatibilità a ritroso totale con le API esistenti senza modifiche lato client.
        """
        if not messages:
            return "default_conv"
        
        # Identifica la sessione usando l'hash del primo messaggio utente
        first_message_content = messages[0].content
        return hashlib.md5(first_message_content.encode('utf-8')).hexdigest()

    async def optimize_history(
        self,
        messages: List[Message],
        conversation_id: str,
        model: str
    ) -> List[Dict[str, str]]:
        """
        Analizza la cronologia dei messaggi.
        Se la lunghezza supera la soglia CONVERSATION_MEMORY_MAX_MESSAGES,
        mantiene solo gli ultimi messaggi recenti e vi premette il riassunto ed i topic
        prelevati da Redis.
        Suscita anche un task asincrono in Celery per rinfrescare il riassunto.
        """
        max_messages = getattr(settings, "CONVERSATION_MEMORY_MAX_MESSAGES", 8)
        
        # Formattazione messaggi per il payload di Ollama
        ollama_messages = [
            {"role": msg.role, "content": msg.content}
            for msg in messages
        ]
        
        # Se la conversazione è corta, la inviamo integralmente
        if len(messages) <= max_messages:
            # Se ci sono almeno 3 messaggi, iniziamo a pre-generare la sintesi in background
            if len(messages) >= 3:
                self._trigger_summary_update(ollama_messages, conversation_id, model)
            return ollama_messages

        # Se supera la soglia, separiamo i messaggi recenti da quelli vecchi
        recent_messages = ollama_messages[-max_messages:]
        
        # Proviamo a recuperare riassunto e argomenti dalla cache Redis
        summary_key = f"conv:{conversation_id}:summary"
        topics_key = f"conv:{conversation_id}:topics"
        
        summary = CacheService.get(summary_key)
        topics = CacheService.get(topics_key)
        
        optimized_list = []

        if summary:
            # Formattiamo il messaggio di sistema con il contesto riassunto
            topics_info = f" (Argomenti trattati: {topics})" if topics else ""
            system_context_msg = (
                f"[CONTESTO PRECEDENTE]\n"
                f"La conversazione passata è stata riassunta come segue:\n"
                f"\"{summary}\"{topics_info}\n"
                f"Usa queste informazioni se l'utente vi fa riferimento."
            )
            optimized_list.append({"role": "system", "content": system_context_msg})
        else:
            # Se non c'è ancora un riassunto (primo sforamento della cache),
            # inviamo l'intera cronologia per non perdere contesto e avviamo la generazione immediata
            logger.info(f"[MEMORY] Nessun riassunto per la conversazione '{conversation_id}' in cache. Invio history completa.")
            self._trigger_summary_update(ollama_messages, conversation_id, model)
            return ollama_messages

        # Aggiungiamo i messaggi della finestra recente
        optimized_list.extend(recent_messages)
        
        # Accoda il task in Celery per rinfrescare il summary in background (include tutti i messaggi)
        self._trigger_summary_update(ollama_messages, conversation_id, model)
        
        return optimized

    def _trigger_summary_update(self, all_messages: List[Dict[str, str]], conversation_id: str, model: str):
        """
        Accoda un task Celery non-blocking per calcolare il summary e i topic in background.
        """
        try:
            generate_summary_and_topics_task.delay(all_messages, conversation_id, model)
            logger.info(f"[MEMORY] Accodato task Celery per aggiornamento memoria della conversazione: {conversation_id}")
        except Exception as e:
            logger.warning(f"[MEMORY] Impossibile avviare il task Celery per memoria conversazione ({e}). Procedo senza aggiornamento.")

# Singleton service
conversation_memory_service = ConversationMemoryService()
