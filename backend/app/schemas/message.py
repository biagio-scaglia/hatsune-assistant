from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class MessageBase(BaseModel):
    role: str = Field(..., description="Il ruolo dell'interlocutore (user, assistant, system)")
    content: str = Field(..., description="Il contenuto testuale del messaggio")

class MessageCreate(MessageBase):
    latency_ms: Optional[int] = Field(None, description="Latenza in ms per la risposta dell'LLM")
    provider: Optional[str] = Field(None, description="Il provider che ha generato la risposta (es: Ollama)")

class MessageRead(MessageBase):
    id: int
    conversation_id: str
    latency_ms: Optional[int]
    provider: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True # SQLAlchemy 2.0 (sostituisce orm_mode=True in Pydantic v2)
