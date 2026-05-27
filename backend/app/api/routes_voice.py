import os
import uuid
import logging
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, Depends, Request, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import settings
from ..core.rate_limit import limiter
from ..core.db import get_db
from ..services.call_service import CallService
from ..services.stt_service import STTService
from ..services.tts_service import AUDIO_DIR
from ..schemas.voice import VoiceTurnResponse, VoiceHealthResponse

logger = logging.getLogger(__name__)

router = APIRouter()
call_service = CallService()
stt_service = STTService()

@router.post("/voice/turn", response_model=VoiceTurnResponse)
@limiter.limit(settings.RATE_LIMIT_CHAT) # Stesso rate limit delle richieste chat
async def voice_turn(
    request: Request,
    file: UploadFile = File(..., description="Il file audio catturato dal client"),
    conversation_id: Optional[str] = Form(None, description="L'ID sessione della chat"),
    model: Optional[str] = Form(None, description="Modello LLM (es. llama3:latest)"),
    voice: Optional[str] = Form(None, description="Voce TTS (es. it_IT-paola-medium)"),
    speed: Optional[float] = Form(None, description="Velocità audio TTS (0.5-2.0)"),
    temperature: Optional[float] = Form(None, description="Temperatura LLM (0.0-1.2)"),
    db: AsyncSession = Depends(get_db)
):
    """
    Pipeline unificata per il turno vocale (Voice Call Mode).
    Accetta in input l'audio registrato dall'utente, esegue STT (Whisper),
    interroga il modello linguistico locale ed infine sintetizza la risposta in audio (Piper TTS).
    """
    request_id = getattr(request.state, "request_id", "unknown")
    logger.info(f"[{request_id}] Richiesta turno vocale. File: {file.filename} | Session: {conversation_id}")

    # Validazione estensioni consentite per l'audio caricato
    allowed_extensions = {".wav", ".pcm", ".mp3", ".m4a", ".aac", ".caf", ".ogg"}
    _, ext = os.path.splitext(file.filename or "")
    if ext.lower() not in allowed_extensions:
        logger.warning(f"[{request_id}] Estensione audio '{ext}' non supportata.")
        raise HTTPException(
            status_code=400,
            detail=f"Formato file '{ext}' non supportato. Formati validi: {', '.join(allowed_extensions)}"
        )

    # Salvataggio temporaneo del file audio caricato all'interno della directory audio del progetto
    temp_filename = f"temp_upload_{uuid.uuid4().hex}{ext.lower()}"
    temp_filepath = os.path.join(AUDIO_DIR, temp_filename)

    try:
        # Scrittura asincrona del file sul disco
        with open(temp_filepath, "wb") as f_out:
            content = await file.read()
            f_out.write(content)
    except Exception as e:
        logger.error(f"[{request_id}] Impossibile scrivere il file audio temporaneo: {e}")
        if os.path.exists(temp_filepath):
            os.remove(temp_filepath)
        raise HTTPException(status_code=500, detail=f"Errore scrittura audio temporaneo: {e}")

    # Eseguiamo l'elaborazione del turno vocale tramite il CallService
    try:
        base_url = str(request.base_url)
        result = await call_service.execute_turn(
            db=db,
            temp_audio_path=temp_filepath,
            conversation_id=conversation_id,
            model=model,
            voice=voice,
            speed=speed,
            temperature=temperature,
            base_url=base_url
        )
        logger.info(f"[{request_id}] Turno vocale completato con successo. ConvID: {result['conversation_id']}")
        return result
    except Exception as e:
        logger.error(f"[{request_id}] Errore interno durante l'elaborazione del turno vocale: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante l'elaborazione del turno vocale: {str(e)}"
        )

@router.get("/voice/health", response_model=VoiceHealthResponse)
async def voice_health():
    """
    Ritorna lo stato diagnostico locale del servizio di trascrizione STT.
    """
    stt_initialized = stt_service._model is not None
    return VoiceHealthResponse(
        success=True,
        stt_initialized=stt_initialized,
        model_size=settings.STT_MODEL_SIZE,
        device=settings.STT_DEVICE,
        compute_type=settings.STT_COMPUTE_TYPE
    )
