import json
import logging
from typing import Any, Optional
from ..core.redis_client import redis_client
from ..core.config import settings

logger = logging.getLogger(__name__)

class CacheService:
    """
    Servizio centralizzato per il caching.
    Gestisce la serializzazione JSON, i log e l'invalidazione della cache.
    """

    @staticmethod
    def get(key: str) -> Optional[Any]:
        """
        Recupera un elemento serializzato in JSON dalla cache.
        Ritorna None in caso di cache miss o se Redis è disabilitato/offline.
        """
        value = redis_client.get(key)
        if value is not None:
            try:
                logger.info(f"[CACHE HIT] Chiave: {key}")
                return json.loads(value)
            except json.JSONDecodeError:
                # Se non è JSON valido, restituisce la stringa grezza
                return value
        logger.info(f"[CACHE MISS] Chiave: {key}")
        return None

    @staticmethod
    def set(key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """
        Salva un elemento nella cache serializzandolo in JSON.
        Se TTL è None, viene utilizzato il default da configurazione.
        """
        if ttl is None:
            ttl = settings.REDIS_CACHE_TTL_SECONDS
        
        try:
            serialized = json.dumps(value)
        except Exception as e:
            logger.error(f"[CACHE] Errore di serializzazione JSON per chiave '{key}': {e}")
            serialized = str(value)

        return redis_client.set(key, serialized, ex=ttl)

    @staticmethod
    def invalidate(key: str) -> bool:
        """Invalidazione esplicita di una singola chiave della cache."""
        logger.info(f"[CACHE INVALIDATE] Chiave: {key}")
        return redis_client.delete(key)

    @staticmethod
    def invalidate_by_pattern(pattern: str) -> int:
        """Invalidazione massiva di tutte le chiavi che corrispondono a un pattern (es: 'ollama:*')."""
        logger.info(f"[CACHE INVALIDATE PATTERN] Pattern: {pattern}")
        keys = redis_client.keys(pattern)
        deleted_count = 0
        for k in keys:
            if redis_client.delete(k):
                deleted_count += 1
        logger.info(f"[CACHE INVALIDATE PATTERN] Rimossi {deleted_count} elementi per pattern '{pattern}'.")
        return deleted_count
