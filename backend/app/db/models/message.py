from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, Text, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from ..base_class import Base

class Message(Base):
    """
    Modello per la tabella 'messages'.
    Rappresenta un singolo messaggio scambiato all'interno di una conversazione.
    """
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    conversation_id: Mapped[str] = mapped_column(
        String(50), 
        ForeignKey("conversations.id", ondelete="CASCADE"), 
        nullable=False
    )
    
    role: Mapped[str] = mapped_column(String(20), nullable=False) # user, assistant, system
    content: Mapped[str] = mapped_column(Text, nullable=False)
    
    latency_ms: Mapped[Optional[int]] = mapped_column(Integer, nullable=True) # Latenza di generazione risposta
    provider: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)   # es. Ollama (Locale), Cloud

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )

    # Relazione ORM inversa verso la conversazione padre
    conversation: Mapped["Conversation"] = relationship("Conversation", back_populates="messages")
