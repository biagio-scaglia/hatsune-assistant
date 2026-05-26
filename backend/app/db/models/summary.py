from datetime import datetime
from sqlalchemy import String, DateTime, Text, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from ..base_class import Base

class ConversationSummary(Base):
    """
    Modello per la tabella 'conversation_summaries'.
    Conserva il riassunto a lungo termine elaborato asincronamente.
    """
    __tablename__ = "conversation_summaries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    conversation_id: Mapped[str] = mapped_column(
        String(50), 
        ForeignKey("conversations.id", ondelete="CASCADE"), 
        unique=True, # Garantisce una relazione stretta 1-a-1
        nullable=False
    )
    
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    
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

    # Relazione ORM inversa verso la conversazione
    conversation: Mapped["Conversation"] = relationship("Conversation", back_populates="summary")
