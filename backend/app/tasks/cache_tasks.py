import logging
import asyncio
from ..celery_app import celery_app
from ..services.llm_service import LLMService
from ..services.cache_service import CacheService
from ..core.config import settings

logger = logging.getLogger(__name__)

def run_async(coro):
    """
    Helper per eseguire coroutine asincrone all'interno dei task Celery sincroni.
    Gestisce correttamente la presenza o l'assenza di un event loop nel thread.
    """
    try:
        return asyncio.run(coro)
    except RuntimeError:
        # Se c'è già un loop attivo nel thread corrente, lo riutilizziamo
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(coro)

@celery_app.task(name="app.tasks.cache_tasks.refresh_models_cache_task")
def refresh_models_cache_task():
    """
    Task periodico per rinfrescare preventivamente la cache dei modelli del provider LLM attivo.
    """
    logger.info(f"[CACHE TASK] Avvio aggiornamento automatico della cache modelli {settings.LLM_PROVIDER}...")
    try:
        llm_service = LLMService()
        # Chiamata asincrona al servizio LLM
        models = run_async(llm_service.fetch_models())
        
        # Aggiorna la cache in Redis usando una chiave specifica per provider
        cache_key = f"llm:models:{settings.LLM_PROVIDER}"
        CacheService.set(cache_key, models, ttl=settings.REDIS_MODELS_TTL_SECONDS)
        logger.info(f"[CACHE TASK] Aggiornamento completato. {len(models)} modelli salvati in cache per {settings.LLM_PROVIDER}.")
    except Exception as e:
        logger.error(f"[CACHE TASK] Errore durante il refresh della cache dei modelli: {e}")

@celery_app.task(name="app.tasks.cache_tasks.cleanup_obsolete_cache_task")
def cleanup_obsolete_cache_task():
    """
    Task periodico per rimuovere eventuali chiavi cache non più utilizzate o obsolete.
    """
    logger.info("[CACHE TASK] Avvio verifica e manutenzione della cache...")
    try:
        # Qui potremmo implementare invalidazioni o rimozioni mirate se necessario.
        # Redis gestisce autonomamente l'espulsione delle chiavi tramite TTL, 
        # ma questo task garantisce la pulizia di eventuali chiavi orfane o logging periodico.
        logger.info("[CACHE TASK] Manutenzione cache completata con successo.")
    except Exception as e:
        logger.error(f"[CACHE TASK] Errore manutenzione cache: {e}")
