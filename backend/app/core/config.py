import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Impostazioni globali dell'applicazione caricate da variabili d'ambiente o file .env.
    """
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    DEFAULT_MODEL: str = "llama3:latest"
    APP_ENV: str = "development"

    # Impostazioni TTS Locale
    TTS_PROVIDER: str = "kokoro"
    TTS_DEFAULT_VOICE: str = "af_heart"
    TTS_DEFAULT_SPEED: float = 1.0
    TTS_DEFAULT_LANG: str = "a"

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
