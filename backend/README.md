# Hatsune Assistant AI Backend

Questo è il backend di servizio in Python (FastAPI) per **Hatsune Assistant**. Funge da bridge (ponte) sicuro, scalabile e ad alte prestazioni tra l'applicazione client in Flutter e le API locali/remote di Ollama, integrando la sintesi vocale locale **Piper TTS** ed ottimizzando l'intera elaborazione tramite **Redis** e **Celery**.

---

## 🚀 Nuove Funzionalità di Ottimizzazione e Scalabilità

Il backend è stato potenziato con un'architettura asincrona avanzata basata su Redis e Celery:

1. **Redis Caching Centralizzato**:
   - Cache con TTL breve (10s) per `/health` per ridurre chiamate ridondanti a Ollama.
   - Cache con TTL medio (5 min) per `/models` per velocizzare il caricamento della lista modelli.
   - **TTS Audio Caching**: Caching dei file audio WAV generati basato sull'hash MD5 di `testo + voce + velocità`. Se la stessa frase viene richiesta, viene servita istantaneamente in meno di 1ms bypassed Piper!
   - Gestione del degrado controllato (*graceful degradation*): se Redis è offline, il backend bypassa la cache e continua a funzionare regolarmente.

2. **Task Asincroni con Celery & Beat**:
   - **Beat (Task Periodici)**:
     - Rimozione programmata dei file WAV temporanei (ogni notte alle 02:00) tramite lock distribuito su Redis.
     - Refresh automatico dei modelli in cache ogni 5 minuti per mantenere i dati pronti in memoria.
     - Manutenzione e cleanup periodico della cache una volta all'ora.
   - **Task in Background**:
     - Sintesi vocale asincrona pesante.
     - Generazione asincrona del riassunto e dei topic della conversazione.

3. **Memoria Conversazionale Ottimizzata**:
   - **Finestra Scorrevole**: Invia a Ollama solo gli ultimi $N$ messaggi recenti (configurabile via `CONVERSATION_MEMORY_MAX_MESSAGES`).
   - **Riassunto & Topic in Background**: Quando la chat supera la soglia, i messaggi storici vengono analizzati asincronamente in Celery per generare un riassunto compatto e 3 topic chiave, salvati in Redis.
   - Nelle richieste successive, il riassunto storico viene allegato come contesto di sistema (`system message`), evitando di saturare la finestra di contesto di Ollama con messaggi vecchi, riducendo drasticamente la latenza.

4. **Diagnostica Amministrativa (`/api/v1/health/diagnostics`)**:
   - Endpoint per monitorare in tempo reale lo stato di Redis (connessione, numero e nomi delle chiavi in cache) e Celery (stato dei worker attivi).

---

## 🛠️ Prerequisiti
- **Python 3.11** o superiore.
- **Ollama** installato ed avviato.
- **Redis** (installato localmente o eseguito tramite Docker).

---

## 🐳 Avvio Rapido con Docker Compose (Raccomandato)

Per facilitare lo sviluppo locale, è presente una configurazione di container completa:

```bash
cd backend
docker-compose up --build
```

Questo comando avvia automaticamente:
- **FastAPI** (`http://localhost:8000`)
- **Redis** (`localhost:6379`)
- **Celery Worker** (gestione dei task asincroni)
- **Celery Beat** (scheduler dei task periodici)
- **Flower** (`http://localhost:5555` - interfaccia di monitoraggio dei task Celery)

---

## ⚙️ Avvio Manuale (Sviluppo Locale)

Se preferisci avviare i servizi localmente senza Docker:

### 1. Avviare Redis
Assicurati che Redis sia attivo sulla porta predefinita `6379`.
- **Windows**: Avvia il servizio Redis tramite WSL (`sudo service redis-server start`) o l'installazione nativa MSI.
- **macOS**: `brew services start redis`

### 2. Configurare l'Ambiente virtuale
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 3. Avviare FastAPI (Backend API)
```powershell
uvicorn app.main:app --reload
```

### 4. Avviare Celery Worker
```powershell
celery -A app.celery_app worker --loglevel=info
```
*(Nota per Windows: se riscontri problemi di concorrenza, puoi forzare la modalità pool singola con `celery -A app.celery_app worker --loglevel=info -P solo`)*

### 5. Avviare Celery Beat (Scheduler)
```powershell
celery -A app.celery_app beat --loglevel=info
```

### 6. Avviare Flower (Monitoraggio Task - Opzionale)
```powershell
celery -A app.celery_app flower --port=5555
```

---

## 📝 Configurazione File `.env`

Il file `.env` contiene le nuove variabili di configurazione di Redis e della memoria conversazionale:

```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development

# Configurazione TTS locale (Piper)
TTS_PROVIDER=piper
TTS_DEFAULT_VOICE=it_IT-paola-medium
TTS_DEFAULT_SPEED=1.0
TTS_DEFAULT_LANG=it

# Configurazione Redis & Celery
REDIS_URL=redis://localhost:6379/0
REDIS_CACHE_TTL_SECONDS=300
REDIS_HEALTH_TTL_SECONDS=10
REDIS_MODELS_TTL_SECONDS=300
CONVERSATION_MEMORY_MAX_MESSAGES=8

# Timeout e Sicurezza
REQUEST_TIMEOUT_SECONDS=60.0
STREAM_TIMEOUT_SECONDS=90.0
CORS_ORIGINS=*
```

---

## 🔌 API Principali ed Integrazioni

### 1. Lista Modelli con Cache (`/api/v1/models`)
- **GET**: Restituisce la lista dei modelli caricati da cache Redis (se presente).
- **POST `/api/v1/models/refresh`**: Invalida esplicitamente la cache dei modelli e avvia un task in background per interpellare Ollama e ripopolarla.

### 2. Sintesi Vocale Intelligente (`/api/v1/tts`)
- **POST**: Genera l'audio. Se lo stesso testo viene richiesto, l'endpoint intercetta l'hash in Redis e restituisce il file WAV istantaneamente, bypassando la generazione di Piper.

### 3. Diagnostica (`/api/v1/health/diagnostics`)
- **GET**: Ritorna lo stato dettagliato di Redis (connesso/offline, conteggio chiavi in cache, chiavi attive) e dei worker Celery.

---

## 🧪 Come Testare i Task Periodici
Per testare i task periodici in sviluppo senza aspettare gli intervalli pianificati:
1. Apri la dashboard di **Flower** (`http://localhost:5555`) per verificare l'esecuzione.
2. Invia una chiamata `POST` a `/api/v1/models/refresh` per forzare l'esecuzione istantanea del task di aggiornamento cache.
3. Puoi invocare direttamente i task nel codice o tramite shell Python per scopi di test:
   ```python
   from app.tasks.cleanup_tasks import cleanup_old_audio_files_task
   cleanup_old_audio_files_task.delay()
   ```
