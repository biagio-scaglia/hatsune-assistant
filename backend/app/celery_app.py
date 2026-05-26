import os
from celery import Celery
from celery.schedules import crontab
from .core.config import settings

# Inizializza l'applicazione Celery
celery_app = Celery(
    "hatsune_tasks",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=[
        "app.tasks.cleanup_tasks",
        "app.tasks.cache_tasks",
        "app.tasks.conversation_tasks",
        "app.tasks.tts_tasks",
    ]
)

# Configurazione dettagliata di Celery con best practices
celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="Europe/Rome",
    enable_utc=True,
    
    # Politiche di pubblicazione affidabili
    task_publish_retry=True,
    task_publish_retry_policy={
        'max_retries': 3,
        'interval_start': 0.2,
        'interval_step': 0.2,
        'interval_max': 1.0,
    },
    
    # Distribuzione equa dei task pesanti (TTS, Ollama)
    worker_prefetch_multiplier=1,
    
    # Conferma il completamento del task solo a esecuzione finita (late ack)
    task_acks_late=True,
    
    # Evita il leak di memoria pulendo i metadati dei task dopo 1 ora
    result_expires=3600,
)

# Configurazione dello scheduler Celery Beat per i job periodici
celery_app.conf.beat_schedule = {
    # Svuotamento dei file audio Wav scaduti ogni notte alle 02:00
    "cleanup-audio-files-nightly": {
        "task": "app.tasks.cleanup_tasks.cleanup_old_audio_files_task",
        "schedule": crontab(hour=2, minute=0),
    },
    # Refresh automatico dei modelli in cache ogni 5 minuti
    "refresh-models-cache-periodic": {
        "task": "app.tasks.cache_tasks.refresh_models_cache_task",
        "schedule": 300.0, # 5 minuti
    },
    # Manutenzione della cache una volta all'ora
    "cleanup-cache-periodic": {
        "task": "app.tasks.cache_tasks.cleanup_obsolete_cache_task",
        "schedule": 3600.0, # 1 ora
    }
}
