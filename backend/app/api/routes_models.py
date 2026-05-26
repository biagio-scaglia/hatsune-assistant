from fastapi import APIRouter
from ..core.config import settings
from ..schemas.model import ModelsListResponse, DefaultModelResponse, ConfigResponse
from ..services.ollama_service import OllamaService

router = APIRouter()
ollama_service = OllamaService()

@router.get("/models", response_model=ModelsListResponse)
async def list_models():
    """
    Ritorna la lista dei modelli caricati localmente ed eseguibili in Ollama.
    """
    models = await ollama_service.fetch_models()
    return ModelsListResponse(
        success=True,
        models=models
    )

@router.get("/models/default", response_model=DefaultModelResponse)
async def get_default_model():
    """
    Ritorna il nome del modello predefinito configurato nel file .env.
    """
    return DefaultModelResponse(
        success=True,
        default_model=settings.DEFAULT_MODEL,
        provider="Ollama (Locale)"
    )

@router.get("/config", response_model=ConfigResponse)
async def get_configuration():
    """
    Espone alcune variabili di configurazione utili al frontend.
    """
    return ConfigResponse(
        success=True,
        ollama_url=settings.OLLAMA_BASE_URL,
        default_model=settings.DEFAULT_MODEL,
        environment=settings.APP_ENV
    )
