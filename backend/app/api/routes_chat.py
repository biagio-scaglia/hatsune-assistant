from datetime import datetime
import logging
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
from ..core.config import settings
from ..core.rate_limit import limiter
from ..schemas.chat import ChatRequest, ChatResponse, Message
from ..services.ollama_service import OllamaService

logger = logging.getLogger(__name__)
router = APIRouter()
ollama_service = OllamaService()

@router.post("/chat", response_model=ChatResponse)
@limiter.limit(settings.RATE_LIMIT_CHAT)
async def chat(chat_request: ChatRequest, request: Request):
    """
    Endpoint di chat sincrono (non-streaming).
    Riceve la cronologia dei messaggi e restituisce la risposta completa di Ollama.
    """
    request_id = getattr(request.state, "request_id", "unknown")
    model = chat_request.model or settings.DEFAULT_MODEL
    
    logger.info(f"[{request_id}] Richiesta chat. Modello: {model} | Messaggi in ingresso: {len(chat_request.messages)}")
    
    ollama_messages = [
        {"role": msg.role, "content": msg.content} 
        for msg in chat_request.messages
    ]
    
    response_data = await ollama_service.chat(
        model=model,
        messages=ollama_messages,
        temperature=chat_request.temperature
    )
    
    assistant_content = response_data.get("message", {}).get("content", "")
    time_str = datetime.now().strftime("%H:%M")
    
    logger.info(f"[{request_id}] Risposta chat generata con successo ({len(assistant_content)} caratteri).")
    
    return ChatResponse(
        success=True,
        message=Message(role="assistant", content=assistant_content),
        model=model,
        time=time_str
    )

@router.post("/chat/stream")
@limiter.limit(settings.RATE_LIMIT_CHAT)
async def chat_stream(chat_request: ChatRequest, request: Request):
    """
    Endpoint di chat in streaming (Server-Sent Events).
    Consente di ricevere la risposta progressivamente per una UX immediata.
    """
    request_id = getattr(request.state, "request_id", "unknown")
    model = chat_request.model or settings.DEFAULT_MODEL
    
    logger.info(f"[{request_id}] Richiesta chat streaming. Modello: {model} | Messaggi in ingresso: {len(chat_request.messages)}")
    
    ollama_messages = [
        {"role": msg.role, "content": msg.content} 
        for msg in chat_request.messages
    ]
    
    generator = await ollama_service.chat_stream(
        model=model,
        messages=ollama_messages,
        temperature=chat_request.temperature
    )
    
    return StreamingResponse(
        generator,
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )
