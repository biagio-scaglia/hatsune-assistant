import time
import uuid
import logging
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)

class TracingMiddleware(BaseHTTPMiddleware):
    """
    Middleware per il tracciamento delle richieste tramite Correlation ID (Request-ID)
    e log dettagliato dei tempi di risposta.
    """
    async def dispatch(self, request: Request, call_next):
        # 1. Rileva o genera un Request-ID univoco
        request_id = request.headers.get("X-Request-ID") or request.headers.get("x-request-id")
        if not request_id:
            request_id = str(uuid.uuid4())
            
        # Salva il request_id nello stato della richiesta per l'uso nei router/log
        request.state.request_id = request_id
        
        # 2. Traccia il tempo di inizio
        start_time = time.time()
        
        client_ip = request.client.host if request.client else "unknown"
        logger.info(
            f"[REQ-START] ID: {request_id} | Client: {client_ip} | "
            f"Method: {request.method} | Path: {request.url.path}"
        )
        
        # 3. Esegue la catena dei filtri e delle route
        try:
            response = await call_next(request)
        except Exception as e:
            duration = (time.time() - start_time) * 1000
            logger.error(
                f"[REQ-ERROR] ID: {request_id} | Path: {request.url.path} | "
                f"Duration: {duration:.2f}ms | Error: {str(e)}"
            )
            raise e
            
        # 4. Calcola il tempo di esecuzione e aggiunge l'header di risposta
        duration = (time.time() - start_time) * 1000
        response.headers["X-Request-ID"] = request_id
        
        logger.info(
            f"[REQ-END] ID: {request_id} | Path: {request.url.path} | "
            f"Status: {response.status_code} | Duration: {duration:.2f}ms"
        )
        
        return response
