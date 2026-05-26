from datetime import datetime
from typing import List, Optional
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from ..base import Base

class Conversation(Base):
    """
    Modello per la tabella 'conversations'.
    Rappresenta una sessione di chat tra l'utente ed Hatsune Miku.
    """
    __tablename__ = "conversations"

    # ID di tipo stringa per compatibilità con l'hash MD5 generato dal client
    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    title: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    active_model: Mapped[str] = mapped_column(String(50), nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        onupdate=func.now(), 
        nullable=False
    )

    # Relazioni ORM
    messages: Mapped[List["Message"]] = relationship(
        "Message", 
        back_populates="conversation", 
        cascade="all, delete-orphan",
        order_by="Message.created_at"
    )
    
    summary: Mapped[Optional["ConversationSummary"]] = relationship(
        "ConversationSummary", 
        back_populates="conversation", 
        cascade="all, delete-orphan",
        uselist=False # Relazione uno-a-uno
    )
    
    topics: Mapped[List["ConversationTopic"]] = relationship(
        "ConversationTopic", 
        back_populates="conversation", 
        cascade="all, delete-orphan"
    )
