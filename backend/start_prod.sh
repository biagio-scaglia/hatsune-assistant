#!/bin/sh
set -e

echo "[STARTUP] Avvio della sequenza di bootstrap in produzione..."

# 1. Esegui migrazioni database SQLAlchemy tramite Alembic
echo "[DATABASE] Applicazione delle migrazioni Alembic..."
alembic upgrade head
echo "[DATABASE] Migrazioni completate con successo."

# 2. Se abilitato, avvia i servizi Celery in background nello stesso container (utile per il Free Tier di Render)
if [ "$RUN_CELERY_IN_WEB" = "true" ]; then
    echo "[CELERY] Rilevata configurazione All-in-One per Free Tier. Avvio Celery worker e beat..."
    
    # Avvia Celery Worker in background
    celery -A app.celery_app worker --loglevel=info > /var/log/celery_worker.log 2>&1 &
    CELERY_WORKER_PID=$!
    echo "[CELERY] Celery Worker avviato in background con PID: $CELERY_WORKER_PID"

    # Avvia Celery Beat in background
    celery -A app.celery_app beat --loglevel=info > /var/log/celery_beat.log 2>&1 &
    CELERY_BEAT_PID=$!
    echo "[CELERY] Celery Beat avviato in background con PID: $CELERY_BEAT_PID"
else
    echo "[CELERY] I servizi Celery non sono avviati in questo container (modalità multi-servizio standard)."
fi

# 3. Avvia FastAPI in primo piano tramite uvicorn
PORT_NUM=${PORT:-8000}
echo "[WEB] Avvio del server FastAPI (Uvicorn) sulla porta $PORT_NUM..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT_NUM"
