import logging
from typing import List, Dict, Any, AsyncGenerator, Optional
from ..core.config import settings
from .base import BaseLLMService
from ..providers.base_provider import BaseLLMProvider
from ..providers.ollama_provider import OllamaProvider
from ..providers.llamacpp_provider import LlamaCppProvider

logger = logging.getLogger(__name__)

class LLMService(BaseLLMService):
    """
    Servizio orchestratore unificato per l'LLM di Hatsune Assistant.
    Implementa BaseLLMService per garantire compatibilità retroattiva completa.
    Legge la configurazione LLM_PROVIDER ed istanzia il provider corretto
    (Ollama o llama.cpp), fungendo da proxy pulito.
    """

    def __init__(self):
        self.provider_type = settings.LLM_PROVIDER.lower().strip()
        self._provider: BaseLLMProvider
        
        if self.provider_type == "llamacpp":
            logger.info("[LLM-SERVICE] Inizializzazione del provider principale: llama.cpp")
            self._provider = LlamaCppProvider()
        else:
            logger.info("[LLM-SERVICE] Inizializzazione del provider principale: Ollama")
            self._provider = OllamaProvider()

    @property
    def provider_name(self) -> str:
        """
        Ritorna il nome leggibile del provider attivo, utile per il tracciamento
        e il salvataggio dei messaggi nel database.
        """
        if self.provider_type == "llamacpp":
            return "llama.cpp (Locale)"
        return "Ollama (Locale)"

    async def check_health(self) -> Dict[str, Any]:
        """
        Delega il controllo di salute al provider attivo.
        """
        try:
            return await self._provider.check_health()
        except Exception as e:
            logger.error(f"[LLM-SERVICE] Errore in check_health sul provider '{self.provider_type}': {e}")
            return {"status": "offline", "version": None, "connected": False}

    async def fetch_models(self) -> List[Dict[str, Any]]:
        """
        Delega il recupero dei modelli disponibili al provider attivo.
        """
        return await self._provider.fetch_models()

    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Invia la chat completa al provider attivo.
        """
        return await self._provider.chat(model=model, messages=messages, temperature=temperature)

    async def chat_stream(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> AsyncGenerator[str, None]:
        """
        Richiede lo streaming SSE al provider attivo.
        """
        return await self._provider.chat_stream(model=model, messages=messages, temperature=temperature)
