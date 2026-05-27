from typing import Optional, Dict
from pydantic import BaseModel, Field

class VoiceTurnResponse(BaseModel):
    """
    Risposta strutturata per un turno di chiamata vocale.
    """
    success: bool = Field(description="Esito del turno vocale")
    transcript: str = Field(description="Il testo trascritto dall'audio dell'utente")
    assistant_text: str = Field(description="La risposta testuale generata da Ollama")
    audio_url: Optional[str] = Field(default=None, description="L'URL del file audio sintetizzato di Miku")
    conversation_id: str = Field(description="ID della sessione di conversazione attiva")
    timing: Dict[str, float] = Field(description="Latenze di elaborazione per ciascuna fase (in secondi)")

class VoiceHealthResponse(BaseModel):
    """
    Stato di salute e diagnostica del servizio Speech-to-Text.
    """
    success: bool
    stt_initialized: bool = Field(description="Indica se il modello Whisper è caricato in memoria")
    model_size: str = Field(description="Dimensione del modello Whisper configurata")
    device: str = Field(description="Dispositivo hardware associato (CPU/CUDA)")
    compute_type: str = Field(description="Tipo di quantizzazione calcolo")
