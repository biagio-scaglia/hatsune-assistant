# Usa un'immagine base leggera di Python
FROM python:3.12-slim

# Imposta variabili d'ambiente utili per Python in Docker
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Imposta la directory di lavoro in /app
WORKDIR /app

# Installa le dipendenze di sistema richieste (ad esempio curl per l'healthcheck, ffmpeg per Whisper, procps per Celery)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copia i file delle dipendenze
COPY requirements.txt .

# Installa le dipendenze Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia il codice dell'applicazione
COPY . .

# Converte i terminatori di riga dello script per compatibilità Unix/Linux e lo rende eseguibile
RUN tr -d '\r' < start_prod.sh > start_prod_lf.sh && \
    mv start_prod_lf.sh start_prod.sh && \
    chmod +x start_prod.sh

# Espone la porta di FastAPI (8000)
EXPOSE 8000

# Avvia l'applicazione tramite lo script di bootstrap di produzione
CMD ["./start_prod.sh"]
