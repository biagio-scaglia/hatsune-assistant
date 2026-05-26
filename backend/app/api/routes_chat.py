from datetime import datetime
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from ..core.config import settings
from ..schemas.chat import ChatRequest, ChatResponse, Message
from ..services.ollama_service import OllamaService

router = APIRouter()
ollama_service = OllamaService()

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Endpoint di chat sincrono (non-streaming).
    Riceve la cronologia dei messaggi e restituisce la risposta completa di Ollama.
    """
    # Se il modello non è fornito, usiamo quello predefinito
    model = request.model or settings.DEFAULT_MODEL
    
    # Convertiamo i messaggi nello schema atteso da Ollama (lista di dizionari)
    ollama_messages = [
        {"role": msg.role, "content": msg.content} 
        for msg in request.messages
    ]
    
    response_data = await ollama_service.chat(
        model=model,
        messages=ollama_messages,
        temperature=request.temperature
    )
    
    assistant_content = response_data.get("message", {}).get("content", "")
    time_str = datetime.now().strftime("%H:%M")
    
    return ChatResponse(
        success=True,
        message=Message(role="assistant", content=assistant_content),
        model=model,
        time=time_str
    )

@router.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """
    Endpoint di chat in streaming (Server-Sent Events).
    Consente di ricevere la risposta progressivamente per una UX immediata.
    """
    model = request.model or settings.DEFAULT_MODEL
    ollama_messages = [
        {"role": msg.role, "content": msg.content} 
        for msg in request.messages
    ]
    
    generator = await ollama_service.chat_stream(
        model=model,
        messages=ollama_messages,
        temperature=request.temperature
    )
    
    # Restituiamo una StreamingResponse con intestazioni SSE appropriate
    return StreamingResponse(
        generator,
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"  # Disabilita il buffering in Nginx se presente come proxy
        }
    )
