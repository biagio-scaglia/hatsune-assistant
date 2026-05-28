import json
import logging
import time
from typing import List, Dict, Any, AsyncGenerator, Optional
import httpx
from ..core.config import settings
from ..core.exceptions import (
    LlamaCppConnectionError,
    LlamaCppAPIError,
    LlamaCppTimeoutError
)
from .base_provider import BaseLLMProvider

logger = logging.getLogger(__name__)

class LlamaCppProvider(BaseLLMProvider):
    """
    Implementazione del provider LLM per llama.cpp server.
    Comunica con l'endpoint OpenAI-compatible `/v1/chat/completions` del server llama.cpp.
    Sfrutta le performance del server, gestendo slot e caching dei prompt.
    """

    def __init__(self):
        self.base_url = settings.LLAMACPP_BASE_URL.rstrip('/')
        self.timeout_config = httpx.Timeout(
            settings.REQUEST_TIMEOUT_SECONDS,
            connect=5.0,
            read=max(settings.REQUEST_TIMEOUT_SECONDS - 5.0, 5.0)
        )
        self.stream_timeout_config = httpx.Timeout(
            settings.STREAM_TIMEOUT_SECONDS,
            connect=5.0,
            read=max(settings.STREAM_TIMEOUT_SECONDS - 5.0, 5.0)
        )

    async def check_health(self) -> Dict[str, Any]:
        """
        Verifica la raggiungibilità e lo stato di salute di llama.cpp server.
        """
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                # Controlla l'endpoint '/health' nativo di llama.cpp
                response = await client.get(f"{self.base_url}/health")
                if response.status_code == 200:
                    data = response.json()
                    status = data.get("status", "ok")
                    # Ritorna lo stato estraendo info utili come slot disponibili
                    return {
                        "status": "ok" if status == "ok" else "degraded",
                        "version": "llama.cpp-server",
                        "connected": True,
                        "slots_idle": data.get("slots_idle"),
                        "slots_processing": data.get("slots_processing")
                    }
                else:
                    return {"status": "degraded", "version": None, "connected": False}
            except (httpx.ConnectError, httpx.NetworkError):
                # Fallback: prova una GET sull'indice principale se /health dà 404
                try:
                    resp = await client.get(self.base_url)
                    if resp.status_code == 200:
                        return {"status": "ok", "version": "llama.cpp-server", "connected": True}
                except Exception:
                    pass
                return {"status": "offline", "version": None, "connected": False}

    async def fetch_models(self) -> List[Dict[str, Any]]:
        """
        Recupera l'elenco dei modelli. Poiché llama.cpp serve solitamente un solo modello pre-caricato,
        interroga `/v1/models` o ritorna il modello di default configurato in .env.
        """
        async with httpx.AsyncClient(timeout=self.timeout_config) as client:
            model_name = settings.LLAMACPP_MODEL_NAME or "llama.cpp"
            try:
                response = await client.get(f"{self.base_url}/v1/models")
                if response.status_code == 200:
                    data = response.json()
                    models_list = data.get("data", [])
                    if models_list:
                        model_name = models_list[0].get("id", model_name)
            except Exception as e:
                logger.warning(f"Impossibile recuperare i modelli da /v1/models ({e}). Uso fallback config.")

            return [{
                "id": model_name,
                "name": model_name,
                "tag": "loaded",
                "size": "N/D (In-Memory)",
                "modified_at": None,
                "provider": "llama.cpp (Locale)",
                "description": "Modello caricato ed eseguito direttamente tramite llama.cpp server."
            }]

    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Invia una richiesta di chat completa (non-stream) a llama.cpp `/v1/chat/completions`.
        """
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "cache_prompt": settings.LLAMACPP_USE_CACHE
        }
        
        # Gestione parametri opzionali di temperatura e slot
        if temperature is not None:
            payload["temperature"] = temperature
        
        # Aggiunta slot se supportati/configurati
        if settings.LLAMACPP_USE_SLOTS and settings.LLAMACPP_DEFAULT_SLOT >= 0:
            payload["slot_id"] = settings.LLAMACPP_DEFAULT_SLOT

        async with httpx.AsyncClient(timeout=self.timeout_config) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/v1/chat/completions",
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
            except (httpx.ConnectError, httpx.NetworkError) as e:
                logger.error(f"Errore di connessione a llama.cpp in chat: {e}")
                raise LlamaCppConnectionError()
            except httpx.TimeoutException:
                raise LlamaCppTimeoutError("La richiesta a llama.cpp è andata in timeout.")

            if response.status_code != 200:
                logger.error(f"llama.cpp /v1/chat/completions ha risposto con codice {response.status_code}: {response.text}")
                raise LlamaCppAPIError(f"Errore chat API llama.cpp (HTTP {response.status_code})")

            data = response.json()
            choices = data.get("choices", [])
            assistant_content = ""
            if choices:
                assistant_content = choices[0].get("message", {}).get("content", "")

            # Mappa la risposta nel formato Ollama atteso dal backend (trasparenza)
            mapped_response = {
                "model": model,
                "message": {
                    "role": "assistant",
                    "content": assistant_content
                },
                "done": True,
                "provider": "llama.cpp",
                "slot_id": data.get("slot_id", -1),
                "tokens_cached": data.get("tokens_cached", 0)
            }
            
            # Copiamo le statistiche se disponibili per eventuale debugging
            if "usage" in data:
                mapped_response["usage"] = data["usage"]

            return mapped_response

    async def chat_stream(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: Optional[float] = None
    ) -> AsyncGenerator[str, None]:
        """
        Invia una richiesta di chat a llama.cpp server e produce chunk in streaming in formato SSE
        omogeneo con quello utilizzato da Ollama nel backend.
        """
        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
            "cache_prompt": settings.LLAMACPP_USE_CACHE
        }
        if temperature is not None:
            payload["temperature"] = temperature
            
        if settings.LLAMACPP_USE_SLOTS and settings.LLAMACPP_DEFAULT_SLOT >= 0:
            payload["slot_id"] = settings.LLAMACPP_DEFAULT_SLOT

        async def generator() -> AsyncGenerator[str, None]:
            async with httpx.AsyncClient(timeout=self.stream_timeout_config) as client:
                try:
                    async with client.stream(
                        "POST",
                        f"{self.base_url}/v1/chat/completions",
                        json=payload,
                        headers={"Content-Type": "application/json"}
                    ) as response:
                        if response.status_code != 200:
                            logger.error(f"llama.cpp stream ha risposto con codice {response.status_code}")
                            raise LlamaCppAPIError(f"Errore chat stream API llama.cpp (HTTP {response.status_code})")

                        async for line in response.aiter_lines():
                            if not line:
                                continue
                            if line.startswith("data: "):
                                data_str = line[6:].strip()
                                if data_str == "[DONE]":
                                    # Genera l'ultimo chunk segnando il termine dello stream
                                    yield f"data: {json.dumps({'content': '', 'done': True, 'provider': 'llama.cpp'})}\n\n"
                                    break
                                
                                try:
                                    chunk = json.loads(data_str)
                                    choices = chunk.get("choices", [])
                                    content = ""
                                    done = False
                                    slot_id = chunk.get("slot_id", -1)
                                    
                                    if choices:
                                        delta = choices[0].get("delta", {})
                                        content = delta.get("content", "")
                                        finish_reason = choices[0].get("finish_reason")
                                        if finish_reason is not None:
                                            done = True

                                    # Costruiamo il chunk standard SSE coerente con il frontend
                                    payload_chunk = {
                                        "content": content,
                                        "done": done,
                                        "provider": "llama.cpp"
                                    }
                                    if slot_id != -1:
                                        payload_chunk["slot_id"] = slot_id

                                    yield f"data: {json.dumps(payload_chunk)}\n\n"
                                    
                                    if done:
                                        break
                                except json.JSONDecodeError:
                                    continue
                except (httpx.ConnectError, httpx.NetworkError) as e:
                    logger.error(f"Errore di connessione a llama.cpp durante lo streaming: {e}")
                    yield f"data: {json.dumps({'error': 'Connessione a llama.cpp interrotta o non disponibile.', 'done': True})}\n\n"
                except httpx.TimeoutException:
                    yield f"data: {json.dumps({'error': 'Timeout della richiesta di streaming llama.cpp.', 'done': True})}\n\n"

        return generator()
