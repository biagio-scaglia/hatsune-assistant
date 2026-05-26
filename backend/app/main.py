import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from .core.config import settings
from .core.logging import setup_logging
from .core.exceptions import register_exception_handlers
from .core.rate_limit import limiter
from .core.middleware import TracingMiddleware
from .api import routes_health, routes_models, routes_chat, routes_tts, routes_conversations


# Configura il logging all'avvio
setup_logging()

# Inizializza l'applicazione FastAPI
app = FastAPI(
    title="Hatsune Assistant AI Backend",
    description="API Bridge con rate limiting, timeout e tracciamento tra frontend Flutter ed Ollama/TTS locale",
    version="1.2.0"
)

# Associa il limiter all'app per slowapi
app.state.limiter = limiter

# Aggiunge il middleware per Correlation ID (Request-ID) e log profiling delle chiamate
app.add_middleware(TracingMiddleware)

# Configura le origini permesse per il CORS da variabili d'ambiente
cors_origins = [o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra la gestione delle eccezioni custom globali
register_exception_handlers(app)

# Determina e crea la cartella per i file statici audio generati
static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
os.makedirs(os.path.join(static_dir, "generated_audio"), exist_ok=True)

# Monta la cartella static per servire i file WAV riproducibili
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Registra i router delle API con il prefisso di versione /api/v1
app.include_router(routes_health.router, prefix="/api/v1", tags=["Health"])
app.include_router(routes_models.router, prefix="/api/v1", tags=["Models"])
app.include_router(routes_chat.router, prefix="/api/v1", tags=["Chat"])
app.include_router(routes_tts.router, prefix="/api/v1", tags=["TTS"])
app.include_router(routes_conversations.router, prefix="/api/v1", tags=["Conversations"])

@app.get("/")
async def root():
    """Endpoint di benvenuto radice."""
    return {
        "app": "Hatsune Assistant AI Backend",
        "status": "active",
        "version": "1.2.0",
        "tts_provider": settings.TTS_PROVIDER,
        "documentation": "/docs"
    }
