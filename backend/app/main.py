from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.logging import setup_logging
from .core.exceptions import register_exception_handlers
from .api import routes_health, routes_models, routes_chat

# Configura il logging all'avvio
setup_logging()

# Inizializza l'applicazione FastAPI
app = FastAPI(
    title="Hatsune Assistant AI Backend",
    description="API Bridge tra il frontend Flutter e Ollama locale/cloud",
    version="1.0.0"
)

# Configura CORS per consentire connessioni dal frontend Flutter (Web, Mobile, Desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Consenti tutte le origini per sviluppo locale
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra la gestione delle eccezioni custom globali
register_exception_handlers(app)

# Registra i router delle API con il prefisso di versione /api/v1
app.include_router(routes_health.router, prefix="/api/v1", tags=["Health"])
app.include_router(routes_models.router, prefix="/api/v1", tags=["Models"])
app.include_router(routes_chat.router, prefix="/api/v1", tags=["Chat"])

@app.get("/")
async def root():
    """Endpoint di benvenuto radice."""
    return {
        "app": "Hatsune Assistant AI Backend",
        "status": "active",
        "documentation": "/docs"
    }
