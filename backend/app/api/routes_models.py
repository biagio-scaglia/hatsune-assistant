from fastapi import APIRouter, Request
from ..core.config import settings
from ..core.rate_limit import limiter
from ..schemas.model import ModelsListResponse, DefaultModelResponse, ConfigResponse
from ..services.ollama_service import OllamaService
from ..services.cache_service import CacheService
from ..tasks.cache_tasks import refresh_models_cache_task

router = APIRouter()
ollama_service = OllamaService()

@router.get("/models", response_model=ModelsListResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def list_models(request: Request):
    """
    Ritorna la lista dei modelli caricati localmente ed eseguibili in Ollama.
    I dati sono salvati in cache Redis per evitare chiamate ripetute a Ollama.
    """
    cache_key = "ollama:models"
    cached_models = CacheService.get(cache_key)
    
    if cached_models:
        return ModelsListResponse(
            success=True,
            models=cached_models
        )
        
    models = await ollama_service.fetch_models()
    
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
    Forza l'invalidazione della cache dei modelli e accoda un task Celery
    per rigenerare i dati in cache in modo asincrono.
    """
    CacheService.invalidate("ollama:models")
    try:
        refresh_models_cache_task.delay()
        return {
            "success": True,
            "message": "Task di refresh modelli accodato in Celery con successo. La cache è stata invalidata."
        }
    except Exception as e:
        # Fallback sincrono se Celery non risponde
        models = await ollama_service.fetch_models()
        CacheService.set("ollama:models", models, ttl=settings.REDIS_MODELS_TTL_SECONDS)
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
        provider="Ollama (Locale)"
    )

@router.get("/config", response_model=ConfigResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def get_configuration(request: Request):
    """
    Espone alcune variabili di configurazione utili al frontend.
    """
    return ConfigResponse(
        success=True,
        ollama_url=settings.OLLAMA_BASE_URL,
        default_model=settings.DEFAULT_MODEL,
        environment=settings.APP_ENV
    )
