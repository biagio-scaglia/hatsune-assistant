from fastapi import APIRouter, Request
from ..core.config import settings
from ..core.rate_limit import limiter
from ..schemas.health import HealthResponse
from ..services.ollama_service import OllamaService

router = APIRouter()
ollama_service = OllamaService()

@router.get("/health", response_model=HealthResponse)
@limiter.limit(settings.RATE_LIMIT_HEALTH)
async def health_check(request: Request):
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
