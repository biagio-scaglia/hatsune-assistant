import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Impostazioni globali dell'applicazione caricate da variabili d'ambiente o file .env.
    """
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    DEFAULT_MODEL: str = "llama3:latest"
    APP_ENV: str = "development"

    # Impostazioni TTS Locale
    TTS_PROVIDER: str = "piper"
    TTS_DEFAULT_VOICE: str = "it_IT-paola-medium"
    TTS_DEFAULT_SPEED: float = 1.0
    TTS_DEFAULT_LANG: str = "it"
    PIPER_MODEL_PATH: Optional[str] = None
    PIPER_CONFIG_PATH: Optional[str] = None
    AUDIO_OUTPUT_DIR: str = "app/static/generated_audio"


    # Impostazioni di Hardening & Timeout
    REQUEST_TIMEOUT_SECONDS: float = 60.0
    STREAM_TIMEOUT_SECONDS: float = 90.0

    # Rate Limiting
    RATE_LIMIT_GLOBAL: str = "100/minute"
    RATE_LIMIT_CHAT: str = "15/minute"
    RATE_LIMIT_TTS: str = "5/minute"
    RATE_LIMIT_HEALTH: str = "120/minute"

    # Validazione Input
    MAX_INPUT_CHARS: int = 2000
    MAX_CONTEXT_MESSAGES: int = 20

    # Sicurezza CORS
    CORS_ORIGINS: str = "*"

    # Configura Pydantic per leggere dal file .env nella radice del backend
    model_config = SettingsConfigDict(
        env_file=os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            ".env"
        ),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
