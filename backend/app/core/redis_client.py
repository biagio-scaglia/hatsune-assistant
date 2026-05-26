import redis
import logging
from typing import Optional
from .config import settings

logger = logging.getLogger(__name__)

class RedisClient:
    """
    Client wrapper per Redis con gestione del degrado controllato (graceful degradation).
    Se Redis non è disponibile, le chiamate non manderanno in crash l'applicazione,
    consentendo al backend di funzionare ignorando la cache.
    """
    def __init__(self):
        self._client: Optional[redis.Redis] = None

    @property
    def client(self) -> Optional[redis.Redis]:
        if self._client is None:
            try:
                # Connessione con decode_responses=True per leggere stringhe Python direttamente
                self._client = redis.Redis.from_url(
                    settings.REDIS_URL, 
                    decode_responses=True,
                    socket_connect_timeout=2.0, # Timeout rapido per evitare blocchi
                    socket_timeout=2.0
                )
                self._client.ping()
                logger.info("Connessione a Redis stabilita con successo.")
            except Exception as e:
                logger.warning(f"[REDIS] Impossibile connettersi a Redis ({e}). Bypass della cache/lock abilitato.")
                self._client = None
        return self._client

    def is_active(self) -> bool:
        """Verifica se Redis è attualmente attivo ed accessibile."""
        try:
            c = self.client
            if c is not None:
                return bool(c.ping())
        except Exception:
            pass
        return False

    def get(self, key: str) -> Optional[str]:
        """Recupera un valore per una chiave, ritorna None in caso di cache miss o errore Redis."""
        try:
            c = self.client
            if c is not None:
                return c.get(key)
        except Exception as e:
            logger.error(f"[REDIS] Errore GET per chiave '{key}': {e}")
        return None

    def set(self, key: str, value: str, ex: Optional[int] = None) -> bool:
        """Imposta una chiave con un valore ed un TTL opzionale. Ritorna False in caso d'errore."""
        try:
            c = self.client
            if c is not None:
                return bool(c.set(key, value, ex=ex))
        except Exception as e:
            logger.error(f"[REDIS] Errore SET per chiave '{key}': {e}")
        return False

    def delete(self, key: str) -> bool:
        """Elimina una chiave. Ritorna True se eliminata con successo, False altrimenti."""
        try:
            c = self.client
            if c is not None:
                return bool(c.delete(key))
        except Exception as e:
            logger.error(f"[REDIS] Errore DELETE per chiave '{key}': {e}")
        return False

    def keys(self, pattern: str) -> list:
        """Cerca chiavi che corrispondono a un pattern. Ritorna lista vuota in caso d'errore."""
        try:
            c = self.client
            if c is not None:
                return list(c.keys(pattern))
        except Exception as e:
            logger.error(f"[REDIS] Errore KEYS per pattern '{pattern}': {e}")
        return []

    def acquire_lock(self, lock_name: str, acquire_timeout: int = 5, expire: int = 60) -> bool:
        """
        Acquisisce un lock distribuito semplice.
        Se Redis è offline, ritorna True per consentire l'esecuzione del task locale (fallback).
        """
        import time
        try:
            c = self.client
            if c is None:
                logger.warning(f"[REDIS LOCK] Redis offline. Eseguo task '{lock_name}' senza lock.")
                return True
            
            identifier = str(time.time())
            end = time.time() + acquire_timeout
            while time.time() < end:
                # nx=True imposta la chiave solo se non esiste già
                if c.set(lock_name, identifier, ex=expire, nx=True):
                    logger.debug(f"[REDIS LOCK] Lock '{lock_name}' acquisito.")
                    return True
                time.sleep(0.1)
        except Exception as e:
            logger.error(f"[REDIS LOCK] Errore acquisizione lock '{lock_name}': {e}")
            return True # Fallback procedendo senza lock
        return False

    def release_lock(self, lock_name: str) -> None:
        """Rilascia un lock precedentemente acquisito."""
        try:
            c = self.client
            if c is not None:
                c.delete(lock_name)
                logger.debug(f"[REDIS LOCK] Lock '{lock_name}' rilasciato.")
        except Exception as e:
            logger.error(f"[REDIS LOCK] Errore rilascio lock '{lock_name}': {e}")

# Istanza singleton globale
redis_client = RedisClient()
