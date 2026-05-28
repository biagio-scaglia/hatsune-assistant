from fastapi import APIRouter, Request
from ..core.config import settings
from ..core.rate_limit import limiter
from ..schemas.model import ModelsListResponse, DefaultModelResponse, ConfigResponse
from ..services.llm_service import LLMService
from ..services.cache_service import CacheService
from ..tasks.cache_tasks import refresh_models_cache_task

router = APIRouter()
llm_service = LLMService()

@router.get("/models", response_model=ModelsListResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def list_models(request: Request):
    """
    Ritorna la lista dei modelli caricati localmente ed eseguibili nel provider LLM attivo.
    I dati sono salvati in cache Redis per evitare chiamate ripetute al provider.
    """
    cache_key = f"llm:models:{settings.LLM_PROVIDER}"
    cached_models = CacheService.get(cache_key)
    
    if cached_models:
        return ModelsListResponse(
            success=True,
            models=cached_models
        )
        
    models = await llm_service.fetch_models()
    
    # Salva in cache per REDIS_MODELS_TTL_SECONDS
    CacheService.set(cache_key, models, ttl=settings.REDIS_MODELS_TTL_SECONDS)
    
    return ModelsListResponse(
        success=True,
        models=models
    )

@router.post("/models/refresh")
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def refresh_models(request: Request):
    """
    Forza l'invalidazione della cache dei modelli per il provider LLM attivo e accoda
    un task Celery per rigenerare i dati in cache in modo asincrono.
    """
    cache_key = f"llm:models:{settings.LLM_PROVIDER}"
    CacheService.invalidate(cache_key)
    try:
        refresh_models_cache_task.delay()
        return {
            "success": True,
            "message": f"Task di refresh modelli accodato in Celery con successo per {settings.LLM_PROVIDER}. La cache è stata invalidata."
        }
    except Exception as e:
        # Fallback sincrono se Celery non risponde
        models = await llm_service.fetch_models()
        CacheService.set(cache_key, models, ttl=settings.REDIS_MODELS_TTL_SECONDS)
        return {
            "success": True,
            "message": f"Bypass Celery: cache rigenerata sincronicamente causa errore: {e}."
        }

@router.get("/models/default", response_model=DefaultModelResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def get_default_model(request: Request):
    """
    Ritorna il nome del modello predefinito configurato nel file .env.
    """
    return DefaultModelResponse(
        success=True,
        default_model=settings.DEFAULT_MODEL,
        provider=llm_service.provider_name
    )

@router.get("/config", response_model=ConfigResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def get_configuration(request: Request):
    """
    Espone alcune variabili di configurazione utili al frontend.
    """
    active_url = settings.LLAMACPP_BASE_URL if settings.LLM_PROVIDER == "llamacpp" else settings.OLLAMA_BASE_URL
    return ConfigResponse(
        success=True,
        ollama_url=active_url,
        default_model=settings.DEFAULT_MODEL,
        environment=settings.APP_ENV
    )
