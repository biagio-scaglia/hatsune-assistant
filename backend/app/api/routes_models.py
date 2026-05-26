from fastapi import APIRouter, Request
from ..core.config import settings
from ..core.rate_limit import limiter
from ..schemas.model import ModelsListResponse, DefaultModelResponse, ConfigResponse
from ..services.ollama_service import OllamaService

router = APIRouter()
ollama_service = OllamaService()

@router.get("/models", response_model=ModelsListResponse)
@limiter.limit(settings.RATE_LIMIT_GLOBAL)
async def list_models(request: Request):
    """
    Ritorna la lista dei modelli caricati localmente ed eseguibili in Ollama.
    """
    models = await ollama_service.fetch_models()
    return ModelsListResponse(
        success=True,
        models=models
    )

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
