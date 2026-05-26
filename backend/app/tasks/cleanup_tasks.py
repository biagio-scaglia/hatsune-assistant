import os
import time
import logging
from ..celery_app import celery_app
from ..core.redis_client import redis_client

logger = logging.getLogger(__name__)

# Risoluzione della directory dei file statici audio generati
CURRENT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(CURRENT_DIR, "static", "generated_audio")

@celery_app.task(name="app.tasks.cleanup_tasks.cleanup_old_audio_files_task")
def cleanup_old_audio_files_task():
    """
    Task periodico per rimuovere i file audio WAV temporanei più vecchi di 10 minuti.
    Utilizza un lock distribuito Redis per evitare doppie esecuzioni simultanee su cluster.
    """
    lock_name = "lock:cleanup_audio_files"
    
    # Tentiamo di acquisire il lock per 5 secondi (scadenza automatica a 60 secondi in caso di crash)
    if not redis_client.acquire_lock(lock_name, acquire_timeout=5, expire=60):
        logger.info("[CLEANUP TASK] Lock già acquisito da un altro worker. Salto questo turno.")
        return

    logger.info("[CLEANUP TASK] Avvio manutenzione e pulizia file audio temporanei...")
    deleted_count = 0
    try:
        if not os.path.exists(AUDIO_DIR):
            logger.warning(f"[CLEANUP TASK] Directory audio non trovata: {AUDIO_DIR}")
            return

        now = time.time()
        files = [
            os.path.join(AUDIO_DIR, f) 
            for f in os.listdir(AUDIO_DIR) 
            if f.startswith("audio_") and f.endswith(".wav")
        ]

        # 1. Elimina file più vecchi di 10 minuti (600 secondi)
        for filepath in files:
            try:
                if now - os.path.getmtime(filepath) > 600:
                    os.remove(filepath)
                    deleted_count += 1
                    logger.info(f"[CLEANUP TASK] Rimosso file scaduto: {os.path.basename(filepath)}")
            except OSError as e:
                logger.error(f"[CLEANUP TASK] Errore durante l'eliminazione di {filepath}: {e}")

        # 2. Se rimangono più di 50 file, ordina e ripulisci i più vecchi
        files = [
            os.path.join(AUDIO_DIR, f) 
            for f in os.listdir(AUDIO_DIR) 
            if f.startswith("audio_") and f.endswith(".wav")
        ]
        if len(files) > 50:
            files.sort(key=os.path.getmtime)
            for filepath in files[:-50]:
                try:
                    os.remove(filepath)
                    deleted_count += 1
                    logger.info(f"[CLEANUP TASK] Rimosso file in eccesso: {os.path.basename(filepath)}")
                except OSError as e:
                    logger.error(f"[CLEANUP TASK] Errore durante l'eliminazione dell'eccedenza {filepath}: {e}")

        logger.info(f"[CLEANUP TASK] Pulizia completata. File rimossi in questo ciclo: {deleted_count}")
    
    except Exception as e:
        logger.error(f"[CLEANUP TASK] Errore durante il processo di cleanup: {e}")
    
    finally:
        # Rilascia sempre il lock Redis
        redis_client.release_lock(lock_name)
