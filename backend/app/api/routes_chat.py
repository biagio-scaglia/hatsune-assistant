from datetime import datetime
import logging
import json
from fastapi import APIRouter, Request, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.config import settings
from ..core.rate_limit import limiter
from ..core.db import get_db, async_session_maker
from ..schemas.chat import ChatRequest, ChatResponse, Message
from ..services.ollama_service import OllamaService
from ..services.conversation_memory_service import conversation_memory_service
from ..db.repositories.conversation_repository import ConversationRepository

logger = logging.getLogger(__name__)
router = APIRouter()
ollama_service = OllamaService()

@router.post("/chat", response_model=ChatResponse)
@limiter.limit(settings.RATE_LIMIT_CHAT)
async def chat(
    chat_request: ChatRequest, 
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Endpoint di chat sincrono (non-streaming).
    Salva la cronologia su Postgres, ottimizza il contesto e persiste la risposta.
    """
    request_id = getattr(request.state, "request_id", "unknown")
    model = chat_request.model or settings.DEFAULT_MODEL
    
    # Calcola l'ID sessione
    conversation_id = conversation_memory_service.get_conversation_id(chat_request.messages)
    
    logger.info(f"[{request_id}] Richiesta chat. Modello: {model} | ID Conversazione: {conversation_id}")
    
    # Ottimizzazione memoria conversazionale (summary + ultimi N messaggi)
    optimized_messages = await conversation_memory_service.optimize_history(
        db=db,
        messages=chat_request.messages,
        conversation_id=conversation_id,
        model=model
    )
    
    # Chiama Ollama
    response_data = await ollama_service.chat(
        model=model,
        messages=optimized_messages,
        temperature=chat_request.temperature
    )
    
    assistant_content = response_data.get("message", {}).get("content", "")
    time_str = datetime.now().strftime("%H:%M")
    
    # Salva la risposta dell'assistente nel database
    if assistant_content.strip():
        db_saved = False
        if not conversation_memory_service.db_offline:
            try:
                await ConversationRepository.add_message(
                    db=db,
                    conversation_id=conversation_id,
                    role="assistant",
                    content=assistant_content,
                    provider="Ollama (Locale)"
                )
                db_saved = True
            except Exception as e:
                logger.warning(f"[DATABASE] Impossibile salvare il messaggio sincrono su Postgres ({e}).")
        
        if not db_saved:
            conversation_memory_service.add_local_message(
                conversation_id=conversation_id,
                role="assistant",
                content=assistant_content
            )
    
    logger.info(f"[{request_id}] Risposta chat salvata su DB e restituita.")
    
    return ChatResponse(
        success=True,
        message=Message(role="assistant", content=assistant_content),
        model=model,
        time=time_str
    )

@router.post("/chat/stream")
@limiter.limit(settings.RATE_LIMIT_CHAT)
async def chat_stream(
    chat_request: ChatRequest, 
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Endpoint di chat in streaming.
    Ottimizza il contesto e risponde progressivamente, salvando la risposta completa
    su PostgreSQL al termine dello streaming.
    """
    request_id = getattr(request.state, "request_id", "unknown")
    model = chat_request.model or settings.DEFAULT_MODEL
    
    # Calcola l'ID sessione
    conversation_id = conversation_memory_service.get_conversation_id(chat_request.messages)
    
    logger.info(f"[{request_id}] Richiesta chat streaming. Modello: {model} | ID Conversazione: {conversation_id}")
    
    # Ottimizzazione memoria conversazionale (summary + ultimi N messaggi)
    optimized_messages = await conversation_memory_service.optimize_history(
        db=db,
        messages=chat_request.messages,
        conversation_id=conversation_id,
        model=model
    )
    
    generator = await ollama_service.chat_stream(
        model=model,
        messages=optimized_messages,
        temperature=chat_request.temperature
    )
    
    # Avvolge il generatore per accumulare la risposta e salvarla su Postgres alla fine
    async def save_stream_response():
        accumulated_content = ""
        async for chunk in generator:
            yield chunk
            
            # Tenta di estrarre il testo dal chunk SSE
            if chunk.startswith("data: "):
                try:
                    data_str = chunk[6:].strip()
                    data_json = json.loads(data_str)
                    content_part = data_json.get("content", "")
                    accumulated_content += content_part
                    
                    if data_json.get("done", False):
                        if accumulated_content.strip():
                            db_saved = False
                            if not conversation_memory_service.db_offline:
                                try:
                                    # Eseguiamo il salvataggio in una sessione DB fresca per evitare
                                    # la chiusura prematura del thread-bound session
                                    async with async_session_maker() as session:
                                        await ConversationRepository.add_message(
                                            session,
                                            conversation_id=conversation_id,
                                            role="assistant",
                                            content=accumulated_content,
                                            provider="Ollama (Locale)"
                                        )
                                    db_saved = True
                                    logger.info(f"[CHAT STREAM] Risposta accumulata ({len(accumulated_content)} crt) salvata su DB.")
                                except Exception as e:
                                    logger.warning(f"[DATABASE] Impossibile salvare la risposta dello stream su Postgres ({e}).")
                            
                            if not db_saved:
                                conversation_memory_service.add_local_message(
                                    conversation_id=conversation_id,
                                    role="assistant",
                                    content=accumulated_content
                                )
                except Exception as e:
                    logger.error(f"[CHAT STREAM] Errore accumulo risposta streaming: {e}")

    return StreamingResponse(
        save_stream_response(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )
