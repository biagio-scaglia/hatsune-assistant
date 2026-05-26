import logging
import asyncio
from ..celery_app import celery_app
from ..services.tts_service import TTSService

logger = logging.getLogger(__name__)

def run_async(coro):
    """Helper per eseguire coroutine in thread sincroni."""
    try:
        return asyncio.run(coro)
    except RuntimeError:
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(coro)

@celery_app.task(name="app.tasks.tts_tasks.synthesize_speech_task")
def synthesize_speech_task(text: str, voice: str, speed: float) -> str:
    """
    Task Celery per eseguire la sintesi vocale (TTS) in background.
    Restituisce il nome del file WAV generato.
    """
    logger.info(f"[TTS TASK] Avvio sintesi vocale in background per testo di {len(text)} caratteri...")
    try:
        tts_service = TTSService()
        filename = run_async(
            tts_service.synthesize(
                text=text,
                voice=voice,
                speed=speed
            )
        )
        logger.info(f"[TTS TASK] Sintesi completata con successo in Celery. File generato: {filename}")
        return filename
    except Exception as e:
        logger.error(f"[TTS TASK] Errore durante la sintesi vocale: {e}")
        raise e
