# Hatsune Assistant AI Backend

Questo è il backend di servizio in Python (FastAPI) per Hatsune Assistant. Funge da bridge (ponte) sicuro, scalabile e ad alte prestazioni tra l'applicazione client in Flutter e le API locali/remote di Ollama, integrando la sintesi vocale locale Piper TTS ed ottimizzando l'elaborazione tramite PostgreSQL, Redis e Celery.

---

## Architettura di Ottimizzazione e Persistenza Dati

Il backend adotta un'architettura a tre livelli per garantire persistenza reale, reattività e bassa latenza:

1. **PostgreSQL (Persistenza dei Dati)**:
   - Utilizzato come fonte di verità principale (Single Source of Truth).
   - Memorizza le conversazioni, lo storico completo di tutti i messaggi (comprensivo di latenze dei modelli e provider), i summary generati asincronamente e gli argomenti estratti.
   - Gestito tramite SQLAlchemy 2.x in modalità asincrona con driver asyncpg per garantire massime prestazioni su operazioni I/O.
   - Migrazioni dello schema gestite tramite Alembic in modalità asincrona.

2. **Redis (Caching & Broker Celery)**:
   - Funge da broker di messaggi per Celery ed backend dei risultati.
   - Fornisce un livello di caching rapido per risposte di health (TTL 10s), lista modelli (TTL 5m), e per i summary/topic delle conversazioni attive.
   - Caching audio TTS basato su hash MD5 di testo, voce e velocità: se la stessa frase viene richiesta, l'URL del file WAV esistente viene servito in meno di 1ms bypassando la generazione C++ di Piper.
   - Gestione del degrado controllato (graceful degradation): se Redis è offline, il sistema bypassa la cache e interroga direttamente il database o Ollama senza interrompere il servizio.

3. **Celery & Celery Beat (Asincronia e Job Periodici)**:
   - **Beat**: Gestisce i compiti ricorrenti, tra cui la pulizia dei file temporanei su disco ad una data ora (02:00) tramite lock distribuiti e la manutenzione della cache.
   - **Worker**: Esegue l'elaborazione pesante in background (sintesi vocale e calcolo asincrono di riassunti e topics tramite Ollama) leggendo e scrivendo direttamente su PostgreSQL.

4. **Memoria Conversazionale Ottimizzata**:
   - Invia ad Ollama solo una finestra scorrevole degli ultimi N messaggi recenti (configurato a 8 di default).
   - Quando una chat supera il limite, i messaggi storici vengono letti da Postgres e riassunti in background da Celery, estraendo anche i temi principali della discussione.
   - Nelle interazioni successive, il riassunto e i tag storici vengono inseriti come contesto di sistema (system message), preservando la finestra di contesto di Ollama ed abbassando i tempi di calcolo della risposta.

---

## Prerequisiti
- **Python 3.11** o superiore.
- **Ollama** installato ed avviato.
- **PostgreSQL** e **Redis** installati o eseguiti via Docker.

---

## Avvio Rapido con Docker Compose (Raccomandato)

La configurazione a container è pronta all'uso e configura automaticamente tutti i servizi, incluse le migrazioni iniziali del database:

```bash
cd backend
docker-compose up --build
```

Questo comando avvia:
- **FastAPI Backend** (`http://localhost:8000`)
- **PostgreSQL** (porta `5432` con credenziali di default `postgres/postgres` e database `hatsune_assistant`)
- **Redis** (porta `6379`)
- **Celery Worker** (gestione task in background)
- **Celery Beat** (scheduler compiti pianificati)
- **Flower** (`http://localhost:5555` - monitoraggio delle code dei task)

All'avvio, il container di FastAPI esegue automaticamente `alembic upgrade head` per allineare le tabelle all'ultima migrazione disponibile.

---

## Avvio Manuale (Sviluppo Locale)

Se desideri eseguire i servizi singolarmente sul tuo computer:

### 1. Avviare i Database
Assicurati che PostgreSQL (porta 5432) e Redis (porta 6379) siano attivi sul computer host.
Esempio di creazione del database in PostgreSQL:
```sql
CREATE DATABASE hatsune_assistant;
```

### 2. Configurare l'Ambiente virtuale ed installare le dipendenze
```bash
cd backend
python -m venv venv

# Attivazione venv:
# Windows (PowerShell): .\venv\Scripts\Activate.ps1
# macOS/Linux: source venv/bin/activate

pip install -r requirements.txt
```

### 3. Configurazione del file .env
Crea o modifica il file `.env` inserendo le credenziali e gli URL corretti:
```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development

# Configurazione database PostgreSQL asincrono
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/hatsune_assistant

# Configurazione Redis
REDIS_URL=redis://localhost:6379/0
REDIS_CACHE_TTL_SECONDS=300
REDIS_HEALTH_TTL_SECONDS=10
REDIS_MODELS_TTL_SECONDS=300
CONVERSATION_MEMORY_MAX_MESSAGES=8
```

### 4. Eseguire le Migrazioni del Database (Alembic)
Prima di avviare l'applicazione, applica le migrazioni per creare la struttura delle tabelle:
```bash
alembic upgrade head
```

### 5. Avviare i servizi del backend
Esegui ciascun comando in un terminale separato con l'ambiente virtuale attivo:

**FastAPI Server**:
```bash
uvicorn app.main:app --reload
```

**Celery Worker**:
```bash
celery -A app.celery_app worker --loglevel=info
```
*(Nota per Windows: se riscontri problemi di concorrenza, aggiungi l'opzione `-P solo`)*

**Celery Beat (Scheduler)**:
```bash
celery -A app.celery_app beat --loglevel=info
```

---

## Gestione delle Migrazioni con Alembic

Alembic è configurato per lavorare in modalità asincrona. I comandi principali per la gestione dello schema del database sono:

### Creare una nuova migrazione automatica (autogenerate)
Quando modifichi o aggiungi un modello ORM di SQLAlchemy in `app/db/models/`, puoi generare automaticamente il file di migrazione confrontando i modelli con lo stato del database attivo:
```bash
alembic revision --autogenerate -m "Descrizione della modifica"
```
Il file di migrazione verrà creato all'interno della cartella `alembic/versions/`.

### Applicare le migrazioni al database (Upgrade)
Per aggiornare il database all'ultima versione disponibile:
```bash
alembic upgrade head
```

### Annullare l'ultima migrazione applicata (Downgrade)
Per tornare indietro di una versione di migrazione:
```bash
alembic downgrade -1
```

---

## API Principali del Backend

Le API sono disponibili con prefisso `/api/v1/` e documentazione interattiva su `http://localhost:8000/docs`.

### Gestione Conversazioni (Nuove API)
- **`GET /conversations`**: Ritorna la lista di tutte le chat registrate su PostgreSQL in ordine di aggiornamento.
- **`GET /conversations/{id}`**: Ritorna i dettagli strutturati di una specifica chat, comprensivi di summary testuale e tag.
- **`GET /conversations/{id}/messages`**: Restituisce la cronologia completa ed ordinata dei messaggi scambiati.
- **`POST /conversations`**: Crea manualmente una nuova sessione di conversazione nel DB.
- **`DELETE /conversations/{id}`**: Elimina permanentemente una chat ed i suoi messaggi in cascata, invalidando anche i dati presenti in cache Redis.

### Endpoint di Chat e TTS
- **`POST /chat`**: Endpoint standard. Salva i messaggi su Postgres, ottimizza la cronologia tramite summary e topic e persiste la risposta generata dal modello.
- **`POST /chat/stream`**: Endpoint in streaming Server-Sent Events. Ottimizza la cronologia ed accumula progressivamente i token, salvando la risposta dell'assistente nel database Postgres solo a completamento dello streaming.
- **`POST /tts`**: Genera l'audio Piper TTS. Utilizza la cache Redis per saltare il calcolo C++ e servire file WAV identici pregressi.
- **`GET /health/diagnostics`**: Espone lo stato di diagnostica ed integrità di Redis (stato, conteggio e anteprima chiavi salvate) e Celery (presenza e identificativi dei worker attivi).
