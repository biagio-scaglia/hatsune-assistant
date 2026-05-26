from typing import List, Optional
from pydantic import BaseModel, Field
from .chat import Message

class TTSRequest(BaseModel):
    """
    Parametri per la sintesi vocale (TTS).
    """
    text: str = Field(description="Il testo da sintetizzare in voce")
    voice: Optional[str] = Field(default=None, description="La voce da utilizzare (es. af_heart)")
    speed: Optional[float] = Field(default=None, description="La velocita' di riproduzione (0.5-2.0)")

class TTSResponse(BaseModel):
    """
    Risposta dell'endpoint di sintesi vocale.
    """
    success: bool
    audio_url: str = Field(description="URL statico del file audio generato")
    text: str = Field(description="Il testo sintetizzato")
    voice: str = Field(description="La voce utilizzata")
    speed: float = Field(description="La velocita' utilizzata")

class ChatWithTTSRequest(BaseModel):
    """
    Parametri per chattare e ottenere contemporaneamente la risposta vocale.
    """
    model: Optional[str] = Field(default=None, description="Il modello Ollama da utilizzare")
    messages: List[Message] = Field(description="La cronologia dei messaggi scambiati")
    temperature: Optional[float] = Field(default=None, description="Parametro di creativita' del modello")
    voice: Optional[str] = Field(default=None, description="Voce TTS opzionale")
    speed: Optional[float] = Field(default=None, description="Velocita' TTS opzionale")

class ChatWithTTSResponse(BaseModel):
    """
    Risposta unificata che contiene il testo generato dal modello LLM e l'audio sintetizzato.
    """
    success: bool
    message: Message
    model: str
    time: str
    audio_url: Optional[str] = Field(default=None, description="URL del file audio sintetizzato")
    tts_active: bool = Field(description="Indica se la sintesi vocale e' andata a buon fine")
