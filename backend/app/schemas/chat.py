from typing import List, Optional
from pydantic import BaseModel, Field

class Message(BaseModel):
    """
    Rappresenta un singolo messaggio in una conversazione (User, Assistant o System).
    """
    role: str = Field(description="Il ruolo del mittente (user, assistant, system)")
    content: str = Field(description="Il testo del messaggio")

class ChatRequest(BaseModel):
    """
    Parametri per la richiesta di chat.
    """
    model: Optional[str] = Field(default=None, description="Il modello da utilizzare (es. llama3:latest)")
    messages: List[Message] = Field(description="La cronologia dei messaggi scambiati")
    temperature: Optional[float] = Field(default=None, description="Parametro di creatività del modello (0.0-1.0)")

class ChatResponse(BaseModel):
    """
    Risposta strutturata per la chat inviata a Flutter.
    """
    success: bool
    message: Message
    model: str
    time: str
