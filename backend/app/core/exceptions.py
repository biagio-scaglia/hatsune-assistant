from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from slowapi.errors import RateLimitExceeded

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
        request_id = getattr(request.state, "request_id", None)
        content = {
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.message,
            }
        }
        if request_id:
            content["error"]["request_id"] = request_id
            
        return JSONResponse(
            status_code=exc.status_code,
            content=content
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        request_id = getattr(request.state, "request_id", None)
        
        # Costruiamo un messaggio leggibile dai dettagli degli errori
        errors_details = {}
        error_messages = []
        for error in exc.errors():
            loc = " -> ".join(str(l) for l in error.get("loc", []))
            msg = error.get("msg", "Valore non valido")
            errors_details[loc] = msg
            error_messages.append(f"{loc}: {msg}")
            
        friendly_message = "Errore di validazione: " + "; ".join(error_messages)
        
        content = {
            "success": False,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": friendly_message,
                "details": errors_details
            }
        }
        if request_id:
            content["error"]["request_id"] = request_id

        return JSONResponse(
            status_code=400,
            content=content
        )

    @app.exception_handler(RateLimitExceeded)
    async def rate_limit_exception_handler(request: Request, exc: RateLimitExceeded):
        request_id = getattr(request.state, "request_id", None)
        
        content = {
            "success": False,
            "error": {
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Troppe richieste inviate. Riprova più tardi. Dettaglio: {exc.detail}"
            }
        }
        if request_id:
            content["error"]["request_id"] = request_id
            
        headers = {}
        if hasattr(exc, "retry_after") and exc.retry_after:
            headers["Retry-After"] = str(exc.retry_after)

        return JSONResponse(
            status_code=429,
            content=content,
            headers=headers if headers else None
        )
        
    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, "request_id", None)
        
        content = {
            "success": False,
            "error": {
                "code": "UNEXPECTED_ERROR",
                "message": f"Si è verificato un errore inatteso nel backend: {str(exc)}",
            }
        }
        if request_id:
            content["error"]["request_id"] = request_id
            
        return JSONResponse(
            status_code=500,
            content=content
        )
