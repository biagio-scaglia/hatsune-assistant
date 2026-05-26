from datetime import datetime
import logging
from fastapi import APIRouter, Request, HTTPException
from ..core.config import settings
from ..schemas.chat import Message
from ..schemas.tts import TTSRequest, TTSResponse, ChatWithTTSRequest, ChatWithTTSResponse
from ..services.ollama_service import OllamaService
from ..services.tts_service import TTSService

logger = logging.getLogger(__name__)

router = APIRouter()
ollama_service = OllamaService()
tts_service = TTSService()

@router.post("/tts", response_model=TTSResponse)
async def synthesize_text(request: TTSRequest, req: Request):
    """
    Sintetizza il testo fornito in un file audio WAV riproducibile.
    Costruisce e restituisce l'URL statico del file audio generato.
    """
    try:
        filename = await tts_service.synthesize(
            text=request.text,
            voice=request.voice,
            speed=request.speed
        )
        
        # Costruzione dell'URL assoluto statico dynamically
        base_url = str(req.base_url) # Esempio: http://127.0.0.1:8000/
        audio_url = f"{base_url}static/generated_audio/{filename}"
        
        return TTSResponse(
            success=True,
            audio_url=audio_url,
            text=request.text,
            voice=request.voice or settings.TTS_DEFAULT_VOICE,
            speed=request.speed or settings.TTS_DEFAULT_SPEED
        )
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Errore endpoint /tts: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Errore di sintesi vocale interno: {str(e)}"
        )

@router.post("/chat-with-tts", response_model=ChatWithTTSResponse)
async def chat_with_tts(request: ChatWithTTSRequest, req: Request):
    """
    Pipeline unificata (Chat + TTS):
    1. Invia la cronologia dei messaggi ad Ollama per generare la risposta testuale.
    2. Sintetizza la risposta in audio WAV.
    3. Ritorna il testo ed il link dell'audio al client Flutter.
    """
    model = request.model or settings.DEFAULT_MODEL
    ollama_messages = [
        {"role": msg.role, "content": msg.content} 
        for msg in request.messages
    ]
    
    # 1. Chiama Ollama per ottenere la risposta di testo
    try:
        response_data = await ollama_service.chat(
            model=model,
            messages=ollama_messages,
            temperature=request.temperature
        )
    except Exception as e:
        logger.error(f"Errore chiamata Ollama in chat-with-tts: {e}")
        # Se fallisce Ollama (LLM principale), solleviamo l'errore perche' non c'e' testo da leggere
        raise
        
    assistant_content = response_data.get("message", {}).get("content", "")
    time_str = datetime.now().strftime("%H:%M")
    
    # 2. Genera l'audio partendo dalla risposta testuale di Ollama
    audio_url = None
    tts_active = False
    
    if assistant_content.strip():
        try:
            filename = await tts_service.synthesize(
                text=assistant_content,
                voice=request.voice,
                speed=request.speed
            )
            base_url = str(req.base_url)
            audio_url = f"{base_url}static/generated_audio/{filename}"
            tts_active = True
        except Exception as e:
            # Molto importante: se il TTS fallisce (es. per timeout o HW), NON blocchiamo
            # l'intera risposta. Restituiamo comunque il testo generato da Ollama
            # per una migliore tolleranza ai guasti (Fault Tolerance)
            logger.error(f"Sintesi vocale fallita in chat-with-tts ma continuo: {e}")
            tts_active = False

    return ChatWithTTSResponse(
        success=True,
        message=Message(role="assistant", content=assistant_content),
        model=model,
        time=time_str,
        audio_url=audio_url,
        tts_active=tts_active
    )
