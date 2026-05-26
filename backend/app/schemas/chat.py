from typing import List, Optional
from pydantic import BaseModel, Field, field_validator
from ..core.config import settings

class Message(BaseModel):
    """
    Rappresenta un singolo messaggio in una conversazione (User, Assistant o System).
    """
    role: str = Field(description="Il ruolo del mittente (user, assistant, system)")
    content: str = Field(description="Il testo del messaggio")

    @field_validator('role')
    @classmethod
    def validate_role(cls, v: str) -> str:
        role_lower = v.lower().strip()
        allowed = ['user', 'assistant', 'system']
        if role_lower not in allowed:
            raise ValueError(f"Il ruolo deve essere uno tra: {', '.join(allowed)}")
        return role_lower

    @field_validator('content')
    @classmethod
    def validate_content(cls, v: str) -> str:
        content_stripped = v.strip()
        if not content_stripped:
            raise ValueError("Il contenuto del messaggio non può essere vuoto.")
        if len(content_stripped) > settings.MAX_INPUT_CHARS:
            raise ValueError(f"Il messaggio supera la lunghezza massima consentita di {settings.MAX_INPUT_CHARS} caratteri.")
        return content_stripped

class ChatRequest(BaseModel):
    """
    Parametri per la richiesta di chat.
    """
    model: Optional[str] = Field(default=None, description="Il modello da utilizzare (es. llama3:latest)")
    messages: List[Message] = Field(description="La cronologia dei messaggi scambiati")
    temperature: Optional[float] = Field(default=None, description="Parametro di creatività del modello (0.0-1.0)")

    @field_validator('messages')
    @classmethod
    def validate_messages(cls, v: List[Message]) -> List[Message]:
        if not v:
            raise ValueError("La cronologia dei messaggi non può essere vuota.")
        if len(v) > settings.MAX_CONTEXT_MESSAGES:
            raise ValueError(f"La cronologia supera il limite massimo di {settings.MAX_CONTEXT_MESSAGES} messaggi.")
        return v

    @field_validator('temperature')
    @classmethod
    def validate_temperature(cls, v: Optional[float]) -> Optional[float]:
        if v is not None:
            if v < 0.0 or v > 1.2:
                raise ValueError("La temperatura deve essere compresa tra 0.0 e 1.2.")
        return v

class ChatResponse(BaseModel):
    """
    Risposta strutturata per la chat inviata a Flutter.
    """
    success: bool
    message: Message
    model: str
    time: str
