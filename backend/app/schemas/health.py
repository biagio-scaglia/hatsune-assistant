from typing import Optional
from pydantic import BaseModel

class HealthResponse(BaseModel):
    """
    Schema di risposta per l'endpoint di health check.
    """
    status: str
    ollama_connected: bool
    ollama_version: Optional[str] = None
    environment: str
