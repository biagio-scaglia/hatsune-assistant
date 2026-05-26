from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

class BaseAIException(Exception):
    """Eccezione base per il nostro backend AI."""
    def __init__(self, message: str, status_code: int = 500, code: str = "INTERNAL_ERROR"):
        self.message = message
        self.status_code = status_code
        self.code = code
        super().__init__(self.message)

class OllamaConnectionError(BaseAIException):
    """Eccezione lanciata quando Ollama non è raggiungibile o è spento."""
    def __init__(self, message: str = "Impossibile connettersi a Ollama. Assicurati che il servizio sia attivo."):
        super().__init__(message, status_code=503, code="OLLAMA_OFFLINE")

class ModelNotFoundError(BaseAIException):
    """Eccezione lanciata quando il modello richiesto non è installato in Ollama."""
    def __init__(self, model_name: str):
        super().__init__(
            message=f"Il modello '{model_name}' non è stato trovato in Ollama. Scaricalo prima.",
            status_code=404,
            code="MODEL_NOT_FOUND"
        )

class OllamaAPIError(BaseAIException):
    """Eccezione per risposte d'errore (non-200) dall'API di Ollama."""
    def __init__(self, message: str, status_code: int = 502):
        super().__init__(message, status_code=status_code, code="OLLAMA_API_ERROR")

class OllamaTimeoutError(BaseAIException):
    """Eccezione per chiamate a Ollama andate in timeout."""
    def __init__(self, message: str = "La richiesta a Ollama è andata in timeout."):
        super().__init__(message, status_code=504, code="OLLAMA_TIMEOUT")


def register_exception_handlers(app: FastAPI) -> None:
    """Registra gli handler globali per catturare le nostre eccezioni custom."""
    
    @app.exception_handler(BaseAIException)
    async def ai_exception_handler(request: Request, exc: BaseAIException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "error": {
                    "code": exc.code,
                    "message": exc.message,
                }
            }
        )
        
    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "error": {
                    "code": "UNEXPECTED_ERROR",
                    "message": f"Si è verificato un errore inatteso nel backend: {str(exc)}",
                }
            }
        )
