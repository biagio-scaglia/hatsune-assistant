from fastapi import APIRouter, Request
from ..core.config import settings
from ..core.rate_limit import limiter
from ..core.redis_client import redis_client
from ..schemas.health import HealthResponse
from ..services.ollama_service import OllamaService
from ..services.cache_service import CacheService

router = APIRouter()
ollama_service = OllamaService()

@router.get("/health", response_model=HealthResponse)
@limiter.limit(settings.RATE_LIMIT_HEALTH)
async def health_check(request: Request):
    """
    Ritorna lo stato del backend e la connettività locale con l'istanza Ollama.
    Risposta memorizzata in cache temporanea per ridurre il carico sul server.
    """
    cache_key = "ollama:health"
    cached_health = CacheService.get(cache_key)
    
    if cached_health:
        return HealthResponse(
            status=cached_health["status"],
            ollama_connected=cached_health["connected"],
            ollama_version=cached_health["version"],
            environment=settings.APP_ENV
        )
        
    health_data = await ollama_service.check_health()
    
    # Salva in cache per REDIS_HEALTH_TTL_SECONDS
    CacheService.set(cache_key, health_data, ttl=settings.REDIS_HEALTH_TTL_SECONDS)
    
    return HealthResponse(
        status=health_data["status"],
        ollama_connected=health_data["connected"],
        ollama_version=health_data["version"],
        environment=settings.APP_ENV
    )

@router.get("/health/diagnostics")
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def get_diagnostics(request: Request):
    """
    Endpoint amministrativo di diagnostica per verificare lo stato della cache Redis,
    delle chiavi salvate e della connettività con il broker Celery.
    """
    redis_active = redis_client.is_active()
    
    # Recupera l'elenco delle chiavi in cache (se Redis è attivo)
    cache_keys = []
    if redis_active:
        try:
            cache_keys = redis_client.keys("*")
        except Exception:
            pass
            
    # Verifica dello stato di Celery
    celery_status = "offline"
    try:
        from ..celery_app import celery_app
        # Tenta di pingare i worker Celery attivi
        insp = celery_app.control.inspect(timeout=1.0)
        ping_res = insp.ping()
        if ping_res:
            celery_status = "online"
            workers = list(ping_res.keys())
        else:
            celery_status = "no_workers_active"
            workers = []
    except Exception as e:
        celery_status = f"error: {str(e)}"
        workers = []

    return {
        "success": True,
        "redis": {
            "connected": redis_active,
            "url": settings.REDIS_URL.split("@")[-1], # Nasconde le credenziali dell'URL Redis
            "cached_keys_count": len(cache_keys),
            "cached_keys": cache_keys[:30] # Massimo 30 chiavi per non intasare l'output
        },
        "celery": {
            "status": celery_status,
            "active_workers": workers
        },
        "environment": settings.APP_ENV
    }

