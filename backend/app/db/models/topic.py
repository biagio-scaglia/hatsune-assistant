from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, ForeignKey, Integer, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from ..base_class import Base

class ConversationTopic(Base):
    """
    Modello per la tabella 'conversation_topics'.
    Registra gli argomenti principali estratti asincronamente dall'LLM.
    """
    __tablename__ = "conversation_topics"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    conversation_id: Mapped[str] = mapped_column(
        String(50), 
        ForeignKey("conversations.id", ondelete="CASCADE"), 
        nullable=False
    )
    
    topic: Mapped[str] = mapped_column(String(100), nullable=False)
    weight: Mapped[Optional[float]] = mapped_column(Float, default=1.0, nullable=True) # Peso dell'argomento
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )

    # Relazione ORM inversa verso la conversazione
    conversation: Mapped["Conversation"] = relationship("Conversation", back_populates="topics")
