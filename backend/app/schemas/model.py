from typing import List, Optional
from pydantic import BaseModel

class ModelDetail(BaseModel):
    """
    Dettaglio di un singolo modello LLM disponibile in Ollama.
    """
    id: str
    name: str
    tag: str
    size: str
    modified_at: Optional[str] = None
    provider: str = "Ollama (Locale)"
    description: str = "Modello locale caricato tramite ponte API FastAPI."

class ModelsListResponse(BaseModel):
    """
    Lista dei modelli supportati.
    """
    success: bool
    models: List[ModelDetail]

class DefaultModelResponse(BaseModel):
    """
    Risposta che indica il modello predefinito.
    """
    success: bool
    default_model: str
    provider: str

class ConfigResponse(BaseModel):
    """
    Informazioni di configurazione utili per il frontend.
    """
    success: bool
    ollama_url: str
    default_model: str
    environment: str
