from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from .message import MessageRead

class ConversationBase(BaseModel):
    id: str = Field(..., description="Identificativo unico della sessione di chat (MD5 o UUID)")
    title: Optional[str] = Field(None, description="Titolo descrittivo della conversazione")
    active_model: str = Field(..., description="Modello LLM utilizzato nella conversazione")

class ConversationCreate(BaseModel):
    id: str = Field(..., description="L'ID sessione (MD5 o UUID)")
    active_model: str = Field(..., description="Il nome del modello Ollama")
    title: Optional[str] = Field(None, description="Titolo iniziale opzionale")

class ConversationSummaryRead(BaseModel):
    summary: str
    updated_at: datetime

    class Config:
        from_attributes = True

class ConversationTopicRead(BaseModel):
    topic: str
    weight: Optional[float]

    class Config:
        from_attributes = True

class ConversationRead(ConversationBase):
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ConversationDetailRead(ConversationRead):
    messages: List[MessageRead] = Field(default_factory=list)
    summary: Optional[ConversationSummaryRead] = None
    topics: List[ConversationTopicRead] = Field(default_factory=list)

    class Config:
        from_attributes = True
