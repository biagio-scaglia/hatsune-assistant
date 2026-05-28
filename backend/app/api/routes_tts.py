from datetime import datetime
import logging
import hashlib
import os
from fastapi import APIRouter, Request, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.config import settings
from ..core.rate_limit import limiter
from ..core.db import get_db
from ..schemas.chat import Message
from ..schemas.tts import TTSRequest, TTSResponse, ChatWithTTSRequest, ChatWithTTSResponse
from ..services.llm_service import LLMService
from ..services.tts_service import TTSService, AUDIO_DIR
from ..services.conversation_memory_service import conversation_memory_service
from ..services.cache_service import CacheService
from ..db.repositories.conversation_repository import ConversationRepository


logger = logging.getLogger(__name__)

router = APIRouter()
llm_service = LLMService()
tts_service = TTSService()

@router.post("/tts", response_model=TTSResponse)
@limiter.limit(settings.RATE_LIMIT_TTS)
async def synthesize_text(tts_request: TTSRequest, request: Request):
    """
    Sintetizza il testo fornito in un file audio WAV riproducibile.
    Utilizza la cache per evitare la rigenerazione di frasi identiche con lo stesso modello e velocità.
    """
    request_id = getattr(request.state, "request_id", "unknown")
    voice = tts_request.voice or settings.TTS_DEFAULT_VOICE
    speed = tts_request.speed or settings.TTS_DEFAULT_SPEED
    
    # Calcola l'hash univoco della richiesta per il caching dell'audio
    cache_string = f"{tts_request.text}:{voice}:{speed}"
    audio_hash = hashlib.md5(cache_string.encode('utf-8')).hexdigest()
    cache_key = f"tts:audio:{audio_hash}"
    
    logger.info(f"[{request_id}] Richiesta TTS. Caratteri: {len(tts_request.text)} | Voce: {voice} | Velocità: {speed}")
    
    # Verifica se l'audio è già presente in cache ed il file fisico esiste
    cached_filename = CacheService.get(cache_key)
    if cached_filename:
        file_path = os.path.join(AUDIO_DIR, cached_filename)
        if os.path.exists(file_path):
            base_url = str(request.base_url)
            audio_url = f"{base_url}static/generated_audio/{cached_filename}"
            logger.info(f"[{request_id}] Servito file audio da cache Redis (HIT). File: {cached_filename}")
            return TTSResponse(
                success=True,
                audio_url=audio_url,
                text=tts_request.text,
                voice=voice,
                speed=speed
            )

    try:
        filename = await tts_service.synthesize(
            text=tts_request.text,
            voice=tts_request.voice,
            speed=tts_request.speed
        )
        
        # Salva il nome del file in cache Redis per future richieste simili (TTL 12 ore)
        CacheService.set(cache_key, filename, ttl=43200)
        
        base_url = str(request.base_url)
        audio_url = f"{base_url}static/generated_audio/{filename}"
        
        logger.info(f"[{request_id}] TTS completato con successo. File: {filename}")
        
        return TTSResponse(
            success=True,
            audio_url=audio_url,
            text=tts_request.text,
            voice=voice,
            speed=speed
        )
    except ValueError as ve:
        logger.warning(f"[{request_id}] Errore validazione TTS: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[{request_id}] Errore endpoint /tts: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Errore di sintesi vocale interno: {str(e)}"
        )

@router.post("/chat-with-tts", response_model=ChatWithTTSResponse)
@limiter.limit(settings.RATE_LIMIT_TTS)
async def chat_with_tts(
    chat_with_tts_request: ChatWithTTSRequest, 
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Pipeline unificata (Chat + TTS):
    1. Ottimizza la cronologia tramite Postgres e summary.
    2. Chiama Ollama per la risposta testuale.
    3. Persiste i messaggi nel database Postgres.
    4. Sintetizza l'audio WAV (sfruttando la cache audio).
    """
    request_id = getattr(request.state, "request_id", "unknown")
    model = chat_with_tts_request.model or settings.DEFAULT_MODEL
    voice = chat_with_tts_request.voice or settings.TTS_DEFAULT_VOICE
    speed = chat_with_tts_request.speed or settings.TTS_DEFAULT_SPEED
    
    # Calcola l'ID sessione basandosi sull'hash del primo messaggio utente
    conversation_id = conversation_memory_service.get_conversation_id(chat_with_tts_request.messages)
    
    logger.info(f"[{request_id}] Richiesta Chat-With-TTS. Modello: {model} | ID Conversazione: {conversation_id} | Voce: {voice}")
    
    # Ottimizzazione memoria conversazionale (summary + ultimi N messaggi)
    optimized_messages = await conversation_memory_service.optimize_history(
        db=db,
        messages=chat_with_tts_request.messages,
        conversation_id=conversation_id,
        model=model
    )
    
    # 1. Chiama il provider LLM attivo per ottenere la risposta di testo
    try:
        response_data = await llm_service.chat(
            model=model,
            messages=optimized_messages,
            temperature=chat_with_tts_request.temperature
        )
    except Exception as e:
        logger.error(f"[{request_id}] Errore chiamata LLM ({llm_service.provider_name}) in chat-with-tts: {e}")
        raise
        
    assistant_content = response_data.get("message", {}).get("content", "")
    time_str = datetime.now().strftime("%H:%M")
    
    # Salva la risposta dell'assistente in PostgreSQL
    if assistant_content.strip():
        db_saved = False
        if not conversation_memory_service.db_offline:
            try:
                await ConversationRepository.add_message(
                    db=db,
                    conversation_id=conversation_id,
                    role="assistant",
                    content=assistant_content,
                    provider=llm_service.provider_name
                )
                db_saved = True
            except Exception as e:
                logger.warning(f"[DATABASE] Impossibile salvare il messaggio in chat-with-tts su Postgres ({e}).")
        
        if not db_saved:
            conversation_memory_service.add_local_message(
                conversation_id=conversation_id,
                role="assistant",
                content=assistant_content
            )
    
    # 2. Genera l'audio partendo dalla risposta testuale di Ollama (sfruttando il caching audio)
    audio_url = None
    tts_active = False
    
    if assistant_content.strip():
        try:
            # Controllo cache per TTS
            cache_string = f"{assistant_content}:{voice}:{speed}"
            audio_hash = hashlib.md5(cache_string.encode('utf-8')).hexdigest()
            cache_key = f"tts:audio:{audio_hash}"
            
            cached_filename = CacheService.get(cache_key)
            if cached_filename and os.path.exists(os.path.join(AUDIO_DIR, cached_filename)):
                base_url = str(request.base_url)
                audio_url = f"{base_url}static/generated_audio/{cached_filename}"
                tts_active = True
                logger.info(f"[{request_id}] Audio sintetizzato caricato da cache per la chat. File: {cached_filename}")
            else:
                logger.info(f"[{request_id}] Generazione audio per risposta di {len(assistant_content)} caratteri...")
                filename = await tts_service.synthesize(
                    text=assistant_content,
                    voice=chat_with_tts_request.voice,
                    speed=chat_with_tts_request.speed
                )
                
                # Salva in cache Redis
                CacheService.set(cache_key, filename, ttl=43200)
                
                base_url = str(request.base_url)
                audio_url = f"{base_url}static/generated_audio/{filename}"
                tts_active = True
                logger.info(f"[{request_id}] Audio sintetizzato con successo per la chat. File: {filename}")
        except Exception as e:
            logger.error(f"[{request_id}] Sintesi vocale fallita in chat-with-tts ma continuo: {e}")
            tts_active = False

    return ChatWithTTSResponse(
        success=True,
        message=Message(role="assistant", content=assistant_content),
        model=model,
        time=time_str,
        audio_url=audio_url,
        tts_active=tts_active
    )
