from abc import ABC, abstractmethod
from typing import Optional

class BaseTTSService(ABC):
    """
    Classe base astratta che definisce l'interfaccia per la sintesi vocale (TTS).
    Rende facile sostituire Kokoro con altri motori come Piper o servizi cloud.
    """

    @abstractmethod
    async def synthesize(
        self,
        text: str,
        voice: Optional[str] = None,
        speed: Optional[float] = None
    ) -> str:
        """
        Sintetizza il testo fornito in un file audio (es. WAV).
        Restituisce il nome file relativo generato (es: 'audio_123.wav').
        """
        pass
