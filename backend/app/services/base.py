from abc import ABC, abstractmethod
from typing import List, Dict, Any, AsyncGenerator, Optional

class BaseLLMService(ABC):
    """
    Classe base astratta che definisce i metodi richiesti da un servizio LLM.
    Consente di sostituire Ollama con altri provider (es. OpenAI, Anthropic) in futuro.
    """

    @abstractmethod
    async def fetch_models(self) -> List[Dict[str, Any]]:
        """Recupera l'elenco dei modelli disponibili."""
        pass

    @abstractmethod
    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> Dict[str, Any]:
        """Invia una chat completa (non-stream)."""
        pass

    @abstractmethod
    async def chat_stream(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> AsyncGenerator[str, None]:
        """Invia una chat e restituisce i frammenti della risposta in tempo reale (streaming)."""
        pass

    @abstractmethod
    async def check_health(self) -> Dict[str, Any]:
        """Verifica la raggiungibilità e lo stato di salute del provider."""
        pass
