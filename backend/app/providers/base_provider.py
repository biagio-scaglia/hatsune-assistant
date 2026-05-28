from abc import ABC, abstractmethod
from typing import List, Dict, Any, AsyncGenerator, Optional

class BaseLLMProvider(ABC):
    """
    Classe base astratta per i provider LLM di Hatsune Assistant.
    Definisce l'interfaccia comune che ogni provider locale (come Ollama o llama.cpp)
    deve implementare.
    """

    @abstractmethod
    async def fetch_models(self) -> List[Dict[str, Any]]:
        """
        Recupera l'elenco dei modelli disponibili dal provider.
        """
        pass

    @abstractmethod
    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Invia una richiesta di chat completa (non-streaming).
        """
        pass

    @abstractmethod
    async def chat_stream(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> AsyncGenerator[str, None]:
        """
        Invia una richiesta di chat e restituisce i frammenti della risposta
        in tempo reale sotto forma di Server-Sent Events (SSE).
        """
        pass

    @abstractmethod
    async def check_health(self) -> Dict[str, Any]:
        """
        Verifica la connettività e lo stato di salute del provider.
        """
        pass
