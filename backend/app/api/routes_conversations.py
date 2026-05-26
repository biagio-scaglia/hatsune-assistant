import logging
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.db import get_db
from ..core.rate_limit import limiter
from ..db.repositories.conversation_repository import ConversationRepository
from ..schemas.conversation import ConversationRead, ConversationCreate, ConversationDetailRead
from ..schemas.message import MessageRead
from ..schemas.common import StandardResponse

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/conversations", response_model=List[ConversationRead])
async def list_conversations(db: AsyncSession = Depends(get_db)):
    """
    Ritorna la lista di tutte le conversazioni salvate nel database,
    ordinate per la data dell'ultima modifica decrescente.
    """
    try:
        conversations = await ConversationRepository.list_conversations(db)
        return conversations
    except Exception as e:
        logger.error(f"[API] Errore nel caricamento delle conversazioni: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Errore interno durante il caricamento delle conversazioni: {str(e)}"
        )

@router.get("/conversations/{id}", response_model=ConversationDetailRead)
async def get_conversation_detail(id: str, db: AsyncSession = Depends(get_db)):
    """
    Ritorna i dettagli di una singola conversazione, compreso il summary,
    i topic e i messaggi scambiati.
    """
    conversation = await ConversationRepository.get_conversation(db, id)
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Conversazione con ID '{id}' non trovata."
        )
    return conversation

@router.get("/conversations/{id}/messages", response_model=List[MessageRead])
async def get_conversation_messages(id: str, db: AsyncSession = Depends(get_db)):
    """
    Ritorna la cronologia completa di tutti i messaggi associati
    a una data conversazione.
    """
    conversation = await ConversationRepository.get_conversation(db, id)
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Conversazione con ID '{id}' non trovata."
        )
    messages = await ConversationRepository.get_messages(db, id)
    return messages

@router.post("/conversations", response_model=ConversationRead, status_code=status.HTTP_201_CREATED)
async def create_conversation(conv_create: ConversationCreate, db: AsyncSession = Depends(get_db)):
    """
    Crea una nuova conversazione nel database (se non esiste già).
    """
    conversation = await ConversationRepository.get_conversation(db, conv_create.id)
    if conversation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La conversazione con ID '{conv_create.id}' esiste già."
        )
    
    new_conv = await ConversationRepository.create_conversation(
        db, 
        conversation_id=conv_create.id, 
        active_model=conv_create.active_model,
        title=conv_create.title
    )
    return new_conv

@router.delete("/conversations/{id}", response_model=StandardResponse)
async def delete_conversation(id: str, db: AsyncSession = Depends(get_db)):
    """
    Elimina permanentemente una conversazione dal database.
    I messaggi, i summary ed i topic correlati vengono rimossi in cascata (Cascade).
    """
    deleted = await ConversationRepository.delete_conversation(db, id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Impossibile eliminare: conversazione con ID '{id}' non trovata."
        )
    
    # Invalida anche la cache su Redis correlata per coerenza
    from ..services.cache_service import CacheService
    CacheService.invalidate(f"conv:{id}:summary")
    CacheService.invalidate(f"conv:{id}:topics")
    
    return StandardResponse(
        success=True,
        message=f"Conversazione '{id}' ed elementi correlati eliminati con successo."
    )
