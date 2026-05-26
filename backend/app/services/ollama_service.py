import json
import logging
from typing import List, Dict, Any, AsyncGenerator, Optional
import httpx
from ..core.config import settings
from ..core.exceptions import (
    OllamaConnectionError,
    OllamaAPIError,
    OllamaTimeoutError,
    ModelNotFoundError
)
from .base import BaseLLMService

logger = logging.getLogger(__name__)

class OllamaService(BaseLLMService):
    """
    Implementazione concreta del servizio LLM per Ollama.
    Utilizza HTTPX in modo asincrono per interfacciarsi con l'istanza Ollama locale.
    """

    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL.rstrip('/')
        # Configurazione per richieste standard (es: chat, list models)
        self.timeout_config = httpx.Timeout(
            settings.REQUEST_TIMEOUT_SECONDS, 
            connect=5.0, 
            read=max(settings.REQUEST_TIMEOUT_SECONDS - 5.0, 5.0)
        )
        # Configurazione per richieste in streaming
        self.stream_timeout_config = httpx.Timeout(
            settings.STREAM_TIMEOUT_SECONDS,
            connect=5.0,
            read=max(settings.STREAM_TIMEOUT_SECONDS - 5.0, 5.0)
        )

    async def check_health(self) -> Dict[str, Any]:
        """
        Verifica se Ollama è raggiungibile ed estrae la versione.
        """
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                # L'endpoint '/' in Ollama risponde solitamente con "Ollama is running"
                response = await client.get(self.base_url)
                if response.status_code == 200:
                    # Tenta di prendere la versione da /api/version
                    try:
                        ver_resp = await client.get(f"{self.base_url}/api/version")
                        version = ver_resp.json().get("version", "unknown")
                    except Exception:
                        version = "attiva"
                    return {"status": "ok", "version": version, "connected": True}
                else:
                    return {"status": "degraded", "version": None, "connected": False}
            except (httpx.ConnectError, httpx.NetworkError):
                return {"status": "offline", "version": None, "connected": False}

    async def fetch_models(self) -> List[Dict[str, Any]]:
        """
        Recupera tutti i modelli installati localmente in Ollama.
        """
        async with httpx.AsyncClient(timeout=self.timeout_config) as client:
            try:
                response = await client.get(f"{self.base_url}/api/tags")
            except (httpx.ConnectError, httpx.NetworkError) as e:
                logger.error(f"Errore di connessione a Ollama in fetch_models: {e}")
                raise OllamaConnectionError()
            except httpx.TimeoutException:
                raise OllamaTimeoutError("Il caricamento dei modelli è andato in timeout.")

            if response.status_code != 200:
                logger.error(f"Ollama api/tags ha risposto con codice {response.status_code}: {response.text}")
                raise OllamaAPIError(f"Errore caricamento modelli Ollama (HTTP {response.status_code})")

            data = response.json()
            models_list = data.get("models", [])
            processed_models = []

            for m in models_list:
                name = m.get("name", "unknown")
                # Estraiamo il tag dal nome (es. "llama3:latest" -> tag: "latest")
                tag = name.split(":")[-1] if ":" in name else "latest"
                
                # Formattiamo la dimensione in GB o MB leggibili
                size_bytes = m.get("size", 0)
                size_gb = size_bytes / (1024 ** 3)
                if size_gb > 0.1:
                    size_str = f"{size_gb:.2f} GB"
                else:
                    size_str = f"{size_bytes / (1024 ** 2):.0f} MB"

                processed_models.append({
                    "id": name,
                    "name": name,
                    "tag": tag,
                    "size": size_str,
                    "modified_at": m.get("modified_at"),
                    "provider": "Ollama (Locale)",
                    "description": f"Modello locale caricato ed eseguito direttamente tramite Ollama."
                })

            return processed_models

    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Invia una richiesta di chat completa (non-stream) a Ollama.
        """
        payload = {
            "model": model,
            "messages": messages,
            "stream": False
        }
        if temperature is not None:
            payload["options"] = {"temperature": temperature}

        async with httpx.AsyncClient(timeout=self.timeout_config) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/api/chat",
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
            except (httpx.ConnectError, httpx.NetworkError) as e:
                logger.error(f"Errore di connessione a Ollama in chat: {e}")
                raise OllamaConnectionError()
            except httpx.TimeoutException:
                raise OllamaTimeoutError("La richiesta di chat a Ollama è andata in timeout.")

            if response.status_code == 404:
                raise ModelNotFoundError(model)
            elif response.status_code != 200:
                logger.error(f"Ollama api/chat ha risposto con codice {response.status_code}: {response.text}")
                raise OllamaAPIError(f"Errore chat API Ollama (HTTP {response.status_code})")

            return response.json()

    async def chat_stream(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> AsyncGenerator[str, None]:
        """
        Invia una richiesta di chat a Ollama e produce chunk in streaming in formato SSE.
        """
        payload = {
            "model": model,
            "messages": messages,
            "stream": True
        }
        if temperature is not None:
            payload["options"] = {"temperature": temperature}

        async def generator() -> AsyncGenerator[str, None]:
            async with httpx.AsyncClient(timeout=self.stream_timeout_config) as client:
                try:
                    async with client.stream(
                        "POST",
                        f"{self.base_url}/api/chat",
                        json=payload,
                        headers={"Content-Type": "application/json"}
                    ) as response:
                        if response.status_code == 404:
                            raise ModelNotFoundError(model)
                        elif response.status_code != 200:
                            logger.error(f"Ollama api/chat stream ha risposto con codice {response.status_code}")
                            raise OllamaAPIError(f"Errore chat stream API Ollama (HTTP {response.status_code})")

                        async for line in response.aiter_lines():
                            if not line:
                                continue
                            try:
                                chunk = json.loads(line)
                                content = chunk.get("message", {}).get("content", "")
                                done = chunk.get("done", False)
                                # Generiamo chunk formattati come Server-Sent Events (SSE)
                                yield f"data: {json.dumps({'content': content, 'done': done})}\n\n"
                            except json.JSONDecodeError:
                                continue
                except (httpx.ConnectError, httpx.NetworkError) as e:
                    logger.error(f"Errore di connessione a Ollama durante lo streaming: {e}")
                    yield f"data: {json.dumps({'error': 'Connessione a Ollama interrotta o non disponibile.', 'done': True})}\n\n"
                except httpx.TimeoutException:
                    yield f"data: {json.dumps({'error': 'Timeout della richiesta di streaming.', 'done': True})}\n\n"

        return generator()
