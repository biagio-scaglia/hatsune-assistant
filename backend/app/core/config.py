import os
from typing import Optional
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Impostazioni globali dell'applicazione caricate da variabili d'ambiente o file .env.
    """
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    DEFAULT_MODEL: str = "llama3:latest"
    APP_ENV: str = "development"

    # Configurazione LLM Provider ('ollama' o 'llamacpp')
    LLM_PROVIDER: str = "ollama"

    # Configurazione llama.cpp server
    LLAMACPP_BASE_URL: str = "http://localhost:8080"
    LLAMACPP_MODEL_NAME: str = "llama.cpp"
    LLAMACPP_DEFAULT_SLOT: int = -1
    LLAMACPP_CTX_SIZE: int = 4096
    LLAMACPP_USE_CACHE: bool = True
    LLAMACPP_USE_SLOTS: bool = True
    LLAMACPP_USE_SPECULATIVE_DECODING: bool = False

    # Impostazioni TTS Locale
    TTS_PROVIDER: str = "piper"
    TTS_DEFAULT_VOICE: str = "it_IT-paola-medium"
    TTS_DEFAULT_SPEED: float = 1.0
    TTS_DEFAULT_LANG: str = "it"
    PIPER_MODEL_PATH: Optional[str] = None
    PIPER_CONFIG_PATH: Optional[str] = None
    AUDIO_OUTPUT_DIR: str = "app/static/generated_audio"

    # Impostazioni Redis & Caching
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_CACHE_TTL_SECONDS: int = 300
    REDIS_HEALTH_TTL_SECONDS: int = 10
    REDIS_MODELS_TTL_SECONDS: int = 300
    CONVERSATION_MEMORY_MAX_MESSAGES: int = 8

    # Impostazioni Database PostgreSQL
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/hatsune_assistant"

    @field_validator('DATABASE_URL', mode='before')
    @classmethod
    def convert_database_url(cls, v: str) -> str:
        if v and v.startswith('postgresql://'):
            return v.replace('postgresql://', 'postgresql+asyncpg://', 1)
        return v

    # Impostazioni Speech-to-Text (STT) Whisper
    STT_MODEL_SIZE: str = "base"
    STT_DEVICE: str = "auto"
    STT_COMPUTE_TYPE: str = "int8"
    STT_DEFAULT_LANGUAGE: str = "it"
    STT_BEAM_SIZE: int = 5
    STT_MODEL_PATH: Optional[str] = None

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
