# Usa un'immagine base leggera di Python
FROM python:3.12-slim

# Imposta variabili d'ambiente utili per Python in Docker
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Imposta la directory di lavoro in /app
WORKDIR /app

# Installa le dipendenze di sistema richieste (ad esempio curl per l'healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia i file delle dipendenze
COPY requirements.txt .

# Installa le dipendenze Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia il codice dell'applicazione
COPY . .

# Espone la porta di FastAPI (8000)
EXPOSE 8000

# Il comando di default avvia FastAPI con uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
