import os
import time
import logging
import hashlib
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession

from .stt_service import STTService
from .tts_service import TTSService, AUDIO_DIR
from .llm_service import LLMService
from .conversation_memory_service import conversation_memory_service
from .cache_service import CacheService
from ..core.config import settings
from ..schemas.chat import Message
from ..db.repositories.conversation_repository import ConversationRepository

logger = logging.getLogger(__name__)

class CallService:
    """
    Servizio orchestratore per la modalità Chiamata Vocale.
    Esegue la pipeline unificata di un turno vocale: STT -> LLM -> TTS -> DB/Cache.
    """
    def __init__(self):
        self.stt_service = STTService()
        self.llm_service = LLMService()
        self.tts_service = TTSService()

    async def execute_turn(
        self,
        db: AsyncSession,
        temp_audio_path: str,
        conversation_id: Optional[str] = None,
        model: Optional[str] = None,
        voice: Optional[str] = None,
        speed: Optional[float] = None,
        temperature: Optional[float] = None,
        base_url: str = ""
    ) -> Dict[str, Any]:
        """
        Esegue un intero turno vocale misurando i tempi di elaborazione per ciascuna fase.
        """
        status_total = time.time()
        start_total = status_total
        
        active_model = model or settings.DEFAULT_MODEL
        active_voice = voice or settings.TTS_DEFAULT_VOICE
        active_speed = speed or settings.TTS_DEFAULT_SPEED
        active_temp = temperature or settings.TEMPERATURE if hasattr(settings, "TEMPERATURE") else 0.7

        # --- Fase 1: Speech-to-Text (Whisper) ---
        start_stt = time.time()
        try:
            transcript = await self.stt_service.transcribe(temp_audio_path)
            stt_latency = time.time() - start_stt
            logger.info(f"[CALL-VOICE] Trascrizione STT completata in {stt_latency:.2f}s: \"{transcript}\"")
        except Exception as e:
            logger.error(f"[CALL-VOICE] Fallimento nella trascrizione STT: {e}")
            raise RuntimeError(f"Errore Speech-to-Text: {str(e)}")
        finally:
            # Pulisce sempre le tracce audio temporanee caricate dal client
            if os.path.exists(temp_audio_path):
                try:
                    os.remove(temp_audio_path)
                except OSError as oe:
                    logger.warning(f"[CALL-VOICE] Impossibile eliminare il file temporaneo {temp_audio_path}: {oe}")

        # Se la trascrizione è vuota (es. silenzio), interrompiamo subito la pipeline evitando carichi inutili
        if not transcript.strip():
            return {
                "success": True,
                "transcript": "",
                "assistant_text": "Non ho sentito bene, potresti ripetere? 🩵",
                "audio_url": None,
                "conversation_id": conversation_id or "default_conv",
                "timing": {
                    "stt": stt_latency,
                    "llm": 0.0,
                    "tts": 0.0,
                    "total": time.time() - start_total
                }
            }

        # --- Risoluzione ed allineamento dell'ID conversazione ---
        if not conversation_id or conversation_id.strip() == "" or conversation_id == "null":
            # Se è il primo turno, generiamo l'ID basandoci sul testo trascritto
            conversation_id = hashlib.md5(transcript.encode('utf-8')).hexdigest()
            logger.info(f"[CALL-VOICE] Generato nuovo ID conversazione basato su trascrizione: {conversation_id}")

        # --- Fase 2: Caricamento e Ottimizzazione Cronologia ---
        # Recupera i messaggi passati da PostgreSQL o dalla cache locale
        history: List[Message] = []
        use_db = not conversation_memory_service.db_offline
        
        if use_db:
            try:
                db_msgs = await ConversationRepository.get_messages(db, conversation_id)
                history = [Message(role=m.role, content=m.content) for m in db_msgs]
            except Exception as e:
                logger.warning(f"[CALL-VOICE] Errore di lettura dal DB, fallback in-memory: {e}")
                use_db = False

        if not use_db:
            local_msgs = conversation_memory_service._local_history.get(conversation_id, [])
            history = [Message(role=m["role"], content=m["content"]) for m in local_msgs]

        # Aggiunge il messaggio utente (il testo trascritto) in fondo alla cronologia
        history.append(Message(role="user", content=transcript))

        # Ottimizza la cronologia (applica la sliding window a blocchi per prompt caching)
        optimized_messages = await conversation_memory_service.optimize_history(
            db=db,
            messages=history,
            conversation_id=conversation_id,
            model=active_model
        )

        # --- Fase 3: Generazione Risposta Testuale LLM (Attivo) ---
        start_llm = time.time()
        try:
            response_data = await self.llm_service.chat(
                model=active_model,
                messages=optimized_messages,
                temperature=active_temp
            )
            assistant_content = response_data.get("message", {}).get("content", "")
            llm_latency = time.time() - start_llm
            logger.info(f"[CALL-VOICE] Risposta LLM ({self.llm_service.provider_name}) generata in {llm_latency:.2f}s.")
        except Exception as e:
            logger.error(f"[CALL-VOICE] Fallimento nella generazione LLM: {e}")
            raise RuntimeError(f"Errore LLM ({self.llm_service.provider_name}): {str(e)}")

        # Salva la risposta dell'assistente nel DB o in locale
        if assistant_content.strip():
            db_saved = False
            if not conversation_memory_service.db_offline:
                try:
                    await ConversationRepository.add_message(
                        db=db,
                        conversation_id=conversation_id,
                        role="assistant",
                        content=assistant_content,
                        provider=self.llm_service.provider_name
                    )
                    db_saved = True
                except Exception as e:
                    logger.warning(f"[CALL-VOICE] Impossibile salvare la risposta dell'assistente su Postgres ({e}).")
            
            if not db_saved:
                conversation_memory_service.add_local_message(
                    conversation_id=conversation_id,
                    role="assistant",
                    content=assistant_content
                )

        # --- Fase 4: Sintesi Vocale TTS (Piper) ---
        start_tts = time.time()
        audio_url = None
        
        if assistant_content.strip():
            try:
                # Cerca l'audio nella cache veloce di Redis
                cache_string = f"{assistant_content}:{active_voice}:{active_speed}"
                audio_hash = hashlib.md5(cache_string.encode('utf-8')).hexdigest()
                cache_key = f"tts:audio:{audio_hash}"
                
                cached_filename = CacheService.get(cache_key)
                if cached_filename and os.path.exists(os.path.join(AUDIO_DIR, cached_filename)):
                    audio_url = f"{base_url}static/generated_audio/{cached_filename}"
                    logger.info(f"[CALL-VOICE] Risposta audio servita da cache Redis (HIT): {cached_filename}")
                else:
                    # Sintetizza il file audio via Piper
                    filename = await self.tts_service.synthesize(
                        text=assistant_content,
                        voice=active_voice,
                        speed=active_speed
                    )
                    # Aggiorna la cache Redis
                    CacheService.set(cache_key, filename, ttl=43200)
                    audio_url = f"{base_url}static/generated_audio/{filename}"
                    logger.info(f"[CALL-VOICE] Risposta audio sintetizzata via Piper: {filename}")
            except Exception as e:
                logger.error(f"[CALL-VOICE] Sintesi vocale Piper fallita: {e}")
                # Lasciamo audio_url = None, il client leggerà solo il testo o riceverà errore controllato

        tts_latency = time.time() - start_tts
        total_latency = time.time() - start_total

        return {
            "success": True,
            "transcript": transcript,
            "assistant_text": assistant_content,
            "audio_url": audio_url,
            "conversation_id": conversation_id,
            "timing": {
                "stt": stt_latency,
                "llm": llm_latency,
                "tts": tts_latency,
                "total": total_latency
            }
        }
