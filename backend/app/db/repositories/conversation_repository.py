import logging
from typing import List, Optional, Tuple
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from ..models.conversation import Conversation
from ..models.message import Message
from ..models.summary import ConversationSummary
from ..models.topic import ConversationTopic

logger = logging.getLogger(__name__)

class ConversationRepository:
    """
    Repository per gestire le operazioni di CRUD persistente su PostgreSQL
    riguardanti conversazioni, messaggi, summary e argomenti estratti.
    """

    @staticmethod
    async def get_conversation(session: AsyncSession, conversation_id: str) -> Optional[Conversation]:
        """Recupera una conversazione per ID, precaricando summary e topics."""
        stmt = (
            select(Conversation)
            .where(Conversation.id == conversation_id)
            .options(selectinload(Conversation.summary), selectinload(Conversation.topics))
        )
        result = await session.execute(stmt)
        return result.scalars().first()

    @staticmethod
    async def create_conversation(
        session: AsyncSession, 
        conversation_id: str, 
        active_model: str, 
        title: Optional[str] = None
    ) -> Conversation:
        """Crea una nuova conversazione."""
        conversation = Conversation(
            id=conversation_id,
            active_model=active_model,
            title=title
        )
        session.add(conversation)
        await session.commit()
        await session.refresh(conversation)
        logger.info(f"[DB] Creata nuova conversazione con ID: {conversation_id}")
        return conversation

    @classmethod
    async def get_or_create_conversation(
        cls, 
        session: AsyncSession, 
        conversation_id: str, 
        active_model: str, 
        title: Optional[str] = None
    ) -> Tuple[Conversation, bool]:
        """Tenta di recuperare la conversazione; se assente, la crea."""
        conversation = await cls.get_conversation(session, conversation_id)
        if conversation:
            return conversation, False
        
        conversation = await cls.create_conversation(session, conversation_id, active_model, title)
        return conversation, True

    @staticmethod
    async def list_conversations(session: AsyncSession) -> List[Conversation]:
        """Ritorna l'elenco di tutte le conversazioni ordinate per data di aggiornamento decrescente."""
        stmt = select(Conversation).order_by(Conversation.updated_at.desc())
        result = await session.execute(stmt)
        return list(result.scalars().all())

    @classmethod
    async def delete_conversation(cls, session: AsyncSession, conversation_id: str) -> bool:
        """Rimuove fisicamente una conversazione dal database. Cascade gestisce messaggi e summary."""
        stmt = delete(Conversation).where(Conversation.id == conversation_id)
        result = await session.execute(stmt)
        await session.commit()
        deleted = bool(result.rowcount > 0)
        if deleted:
            logger.info(f"[DB] Eliminata conversazione con ID: {conversation_id}")
        return deleted

    @staticmethod
    async def add_message(
        session: AsyncSession, 
        conversation_id: str, 
        role: str, 
        content: str, 
        latency_ms: Optional[int] = None, 
        provider: Optional[str] = None
    ) -> Message:
        """Aggiunge un messaggio a una conversazione, aggiornando la data updated_at della chat."""
        # 1. Inserisci il messaggio
        message = Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
            latency_ms=latency_ms,
            provider=provider
        )
        session.add(message)
        
        # 2. Aggiorna data di modifica della conversazione
        stmt = select(Conversation).where(Conversation.id == conversation_id)
        res = await session.execute(stmt)
        conversation = res.scalars().first()
        if conversation:
            from sqlalchemy.sql import func
            conversation.updated_at = func.now() # Aggiorna data ultima interazione
            
        await session.commit()
        await session.refresh(message)
        logger.info(f"[DB] Aggiunto messaggio {role} alla conversazione: {conversation_id}")
        return message

    @staticmethod
    async def get_messages(session: AsyncSession, conversation_id: str) -> List[Message]:
        """Ottiene la cronologia completa dei messaggi di una conversazione ordinati per creazione."""
        stmt = select(Message).where(Message.conversation_id == conversation_id).order_by(Message.created_at.asc())
        result = await session.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_recent_messages(session: AsyncSession, conversation_id: str, limit: int) -> List[Message]:
        """Ottiene gli ultimi N messaggi ordinati in ordine cronologico crescente."""
        stmt = (
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
        )
        result = await session.execute(stmt)
        recent = list(result.scalars().all())
        # Poiché sono estratti decrescenti per il limit, li ribaltiamo per l'ordine cronologico crescente
        recent.reverse()
        return recent

    @staticmethod
    async def get_summary(session: AsyncSession, conversation_id: str) -> Optional[ConversationSummary]:
        """Ottiene il riassunto della conversazione."""
        stmt = select(ConversationSummary).where(ConversationSummary.conversation_id == conversation_id)
        result = await session.execute(stmt)
        return result.scalars().first()

    @staticmethod
    async def update_or_create_summary(
        session: AsyncSession, 
        conversation_id: str, 
        summary_text: str
    ) -> ConversationSummary:
        """Aggiorna il riassunto esistente o ne crea uno nuovo."""
        stmt = select(ConversationSummary).where(ConversationSummary.conversation_id == conversation_id)
        res = await session.execute(stmt)
        summary = res.scalars().first()

        if summary:
            summary.summary = summary_text
        else:
            summary = ConversationSummary(
                conversation_id=conversation_id,
                summary=summary_text
            )
            session.add(summary)

        await session.commit()
        await session.refresh(summary)
        logger.info(f"[DB] Aggiornato summary per conversazione: {conversation_id}")
        return summary

    @staticmethod
    async def get_topics(session: AsyncSession, conversation_id: str) -> List[ConversationTopic]:
        """Ritorna l'elenco dei topic della conversazione."""
        stmt = select(ConversationTopic).where(ConversationTopic.conversation_id == conversation_id)
        result = await session.execute(stmt)
        return list(result.scalars().all())

    @classmethod
    async def update_topics(
        cls, 
        session: AsyncSession, 
        conversation_id: str, 
        topics_list: List[str]
    ) -> List[ConversationTopic]:
        """Sostituisce i vecchi topic estratti con i nuovi."""
        # 1. Rimuove i topic precedenti
        stmt_del = delete(ConversationTopic).where(ConversationTopic.conversation_id == conversation_id)
        await session.execute(stmt_del)

        # 2. Inserisce i nuovi topic
        new_topics = []
        for index, topic_name in enumerate(topics_list):
            # Calcola un peso decrescente per importanza del topic (es. 1.0, 0.8, 0.6)
            weight = max(1.0 - (index * 0.2), 0.2)
            t = ConversationTopic(
                conversation_id=conversation_id,
                topic=topic_name.strip(),
                weight=weight
            )
            session.add(t)
            new_topics.append(t)

        await session.commit()
        logger.info(f"[DB] Aggiornati {len(new_topics)} topics per conversazione: {conversation_id}")
        return new_topics
