from fastapi import APIRouter
from ..core.config import settings
from ..schemas.health import HealthResponse
from ..services.ollama_service import OllamaService

router = APIRouter()
ollama_service = OllamaService()

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Ritorna lo stato del backend e la connettività locale con l'istanza Ollama.
    """
    health_data = await ollama_service.check_health()
    return HealthResponse(
        status=health_data["status"],
        ollama_connected=health_data["connected"],
        ollama_version=health_data["version"],
        environment=settings.APP_ENV
    )
