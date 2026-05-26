from typing import List, Optional
import re
from pydantic import BaseModel, Field, field_validator
from .chat import Message
from ..core.config import settings

class TTSRequest(BaseModel):
    """
    Parametri per la sintesi vocale (TTS).
    """
    text: str = Field(description="Il testo da sintetizzare in voce")
    voice: Optional[str] = Field(default=None, description="La voce da utilizzare (es. af_heart)")
    speed: Optional[float] = Field(default=None, description="La velocita' di riproduzione (0.5-2.0)")

    @field_validator('text')
    @classmethod
    def validate_text(cls, v: str) -> str:
        text_stripped = v.strip()
        if not text_stripped:
            raise ValueError("Il testo da sintetizzare non può essere vuoto.")
        if len(text_stripped) > settings.MAX_INPUT_CHARS:
            raise ValueError(f"Il testo supera la lunghezza massima consentita di {settings.MAX_INPUT_CHARS} caratteri.")
        return text_stripped

    @field_validator('voice')
    @classmethod
    def validate_voice(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            voice_clean = v.strip()
            if not voice_clean:
                return None
            if not re.match(r'^[a-zA-Z0-9_\-]+$', voice_clean):
                raise ValueError("Il nome della voce può contenere solo caratteri alfanumerici, trattini e underscore (es: it_IT-riccardo-x_low).")
            return voice_clean
        return v

    @field_validator('speed')
    @classmethod
    def validate_speed(cls, v: Optional[float]) -> Optional[float]:
        if v is not None:
            if v < 0.5 or v > 2.0:
                raise ValueError("La velocità del parlato deve essere compresa tra 0.5 e 2.0.")
        return v

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

    @field_validator('voice')
    @classmethod
    def validate_voice(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            voice_clean = v.strip()
            if not voice_clean:
                return None
            if not re.match(r'^[a-zA-Z0-9_\-]+$', voice_clean):
                raise ValueError("Il nome della voce può contenere solo caratteri alfanumerici, trattini e underscore (es: it_IT-riccardo-x_low).")
            return voice_clean
        return v

    @field_validator('speed')
    @classmethod
    def validate_speed(cls, v: Optional[float]) -> Optional[float]:
        if v is not None:
            if v < 0.5 or v > 2.0:
                raise ValueError("La velocità del parlato deve essere compresa tra 0.5 e 2.0.")
        return v

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
