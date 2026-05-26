# Hatsune Assistant

Un assistente alla programmazione interattivo sviluppato in Flutter, con Hatsune Miku come presenza 3D animata collegata a un backend asincrono in Python (FastAPI) connesso a modelli LLM Ollama locali/Cloud, con persistenza dati PostgreSQL, cache Redis, code asincrone Celery e sintesi vocale locale Piper TTS.

Realizzato da biagigio.

---

## Panoramica del Progetto

Hatsune Assistant unisce l'estetica cyberpunk di Hatsune Miku con una interfaccia utente scura, moderna ed estremamente responsive progettata per sviluppatori. L'applicazione si appoggia a un backend asincrono in Python che fa da ponte verso un'istanza locale di Ollama ed è in grado di inviare prompt, gestire lo storico persistente, lo streaming delle risposte, configurare i parametri e caricare i modelli installati. 

Il backend integra la sintesi vocale locale ad alte prestazioni tramite Piper TTS, consentendo all'avatar 3D di Miku di parlare ed animarsi in tempo reale coordinandosi all'output audio generato. Per ottimizzare le latenze, garantire una persistenza reale ed una gestione intelligente del contesto, il sistema utilizza:
- **PostgreSQL** come database relazionale principale per salvare conversazioni, messaggi, summary e argomenti.
- **SQLAlchemy 2.x** in modalità asincrona tramite driver **asyncpg** per un'interazione non bloccante con il database.
- **Alembic** per la gestione evolutiva e controllata dello schema tramite migrazioni.
- **Redis** come livello di caching veloce (per dati di stato, risposte rapide e cache dei file audio WAV generati) e come broker di messaggi per Celery.
- **Celery** e **Celery Beat** per l'esecuzione in background di compiti periodici e pesanti (sintesi vocale ed aggiornamento asincrono dei summary).

### Stati e Pose della Miku 3D
L'avatar 3D cambia posa a seconda dello stato di elaborazione dell'assistente:
- **Idle** (`idle.glb`): Stato di riposo/attesa predefinito (con auto-rotazione attiva).
- **Thinking** (`thinking.glb`): Miku si concentra mentre il backend e Ollama elaborano la risposta.
- **Talking** (`talking.glb`): Miku parla ed espone l'output testuale generato (riproducendo l'audio sintetizzato).
- **Victory** (`victory.glb`): Miku festeggia quando riceve complimenti o riscontri positivi (es. scrivendo "grazie", "bella risposta", "ottimo", "brava", "perfetto" nella chat), per poi tornare automaticamente in stato Idle dopo 5 secondi.

---

## Funzionalita Principali

### Architettura Client-Server e Persistenza
- **FastAPI Python Backend**: Il frontend Flutter comunica con un backend in Python asincrono che funge da bridge sicuro verso Ollama e PostgreSQL.
- **PostgreSQL Database**:
  - Salva in modo strutturato e duraturo le conversazioni, lo storico di tutti i messaggi con data e dettagli tecnici (es. latenza e provider), i summary e i topic delle discussioni.
  - Utilizza un layer repository dedicato (`app/db/repositories/`) per separare la logica delle query SQL dal livello delle API e dei servizi.
- **Caching Centralizzato su Redis**:
  - Cache con TTL breve (10 secondi) per l'endpoint di health `/api/v1/health` e TTL medio (5 minuti) per l'endpoint `/api/v1/models`.
  - **TTS Audio Cache**: Caching dei file audio WAV generati basato sull'hash MD5 di testo, voce e velocità. Se la stessa frase viene richiesta, viene restituito l'URL dell'audio esistente bypassando Piper TTS (latenza inferiore a 1ms).
  - **Bypass e Fallback**: In caso di arresto temporaneo del server Redis, il backend continua a funzionare leggendo direttamente da PostgreSQL ed Ollama.
- **Task Asincroni e Programmati con Celery**:
  - **Beat (Scheduler)**: Gestisce i job periodici, tra cui la pulizia dei file audio temporanei (ogni notte alle 02:00) tramite lock distribuiti e la manutenzione ordinaria della cache.
  - **Worker**: Esegue l'elaborazione pesante in background (sintesi vocale Piper, generazione del summary storico ed estrazione topic tramite Ollama).
- **Memoria Conversazionale Ottimizzata**:
  - **Sliding Window**: Invia ad Ollama solo gli ultimi messaggi recenti (configurabili tramite `CONVERSATION_MEMORY_MAX_MESSAGES`).
  - **Sintesi Storica Asincrona**: Quando la cronologia supera la finestra recente, un task Celery in background riassume i messaggi precedenti ed estrae gli argomenti principali discussi, salvandoli in modo permanente su PostgreSQL e caricandoli in cache Redis.
  - Il riassunto viene iniettato come messaggio di sistema (`system message`) per non saturare la finestra di contesto di Ollama con messaggi vecchi, abbattendo la latenza del modello.
- **Diagnostica e Monitoraggio (`/api/v1/health/diagnostics`)**:
  - Endpoint amministrativo per monitorare in tempo reale lo stato di Redis (connessione, numero e chiavi attive) e di Celery (stato dei worker).

### Integrazione Vocale Piper Standalone
- **Zero installazioni pesanti**: Viene scaricato in background l'eseguibile precompilato ufficiale `piper.exe` per Windows e i modelli ONNX di default al primo avvio.
- **Gestione Voci e Lingue**: Supporta voci italiane femminili di default (`it_IT-paola-medium`), maschili (`it_IT-riccardo-x_low`) ed inglesi (`en_US-lessac-medium`), scaricate automaticamente su richiesta.
- **Fallback Acustico**: Se il download dei modelli è ancora in corso, riproduce un bip sinusoidale cyber.

### Layout Responsive Premium
- **Desktop/Tablet**: Split-screen con barra di navigazione laterale (`NavigationRail`) e visualizzatore Miku 3D persistente sulla destra.
- **Mobile**: Navigazione inferiore (`NavigationBar`) e visualizzatore Miku 3D posizionato in alto, che si nasconde per lasciare spazio ai messaggi quando la tastiera virtuale è aperta.
- **Design System Cyberpunk**: Colori antracite, cyan Miku `#39C5BB` e rosa neon `#FF6B9D`, con effetti Glassmorphism e glow.

---

## Modelli 3D (glTF/GLB)

I file 3D dell'assistente sono inclusi localmente nel progetto. Puoi visualizzarli ed orbitarli in 3D nativo direttamente su GitHub ai seguenti link:

* [Visualizza Modello 3D - Idle (idle.glb)](assets/models/idle.glb)
* [Visualizza Modello 3D - Thinking (thinking.glb)](assets/models/thinking.glb)
* [Visualizza Modello 3D - Talking (talking.glb)](assets/models/talking.glb)
* [Visualizza Modello 3D - Victory (victory.glb)](assets/models/victory.glb)

---

## Stack Tecnologico e Dipendenze

### Frontend (Flutter)
- **Linguaggio**: Dart
- **Framework**: Flutter (Material 3)
- **Dipendenze Chiave**:
  - `model_viewer_plus`: rendering 3D interattivo dei file GLB.
  - `http`: per le chiamate API REST verso il backend FastAPI.
  - `audioplayers`: per la riproduzione dei file audio WAV generati dal backend.
  - `google_fonts`: per i font Rajdhani e Inter.

### Backend (Python)
- **Linguaggio**: Python 3.11+
- **Framework**: FastAPI & Uvicorn (server asincrono)
- **Database & ORM**: PostgreSQL, SQLAlchemy 2.x (async), Alembic (migrazioni)
- **Gestore Coda e Cache**: Redis & Celery (con Celery Beat per compiti periodici)
- **Dipendenze Chiave**:
  - `httpx`: per le chiamate asincrone a Ollama.
  - `asyncpg`: driver asincrono per PostgreSQL.
  - `redis`: client Python per l'interazione con Redis.
  - `celery`: per la gestione della coda dei task asincroni.
  - `pydantic` e `pydantic-settings`: per la validazione dei modelli di dati e delle variabili d'ambiente.
  - `slowapi`: per rate limiting delle chiamate API.
  - **Piper C++ Standalone (`piper.exe`)**: motore TTS locale integrato in modo portabile.

---

## Installazione ed Esecuzione

### Esecuzione Completa tramite Docker Compose (Raccomandato)
Se hai installato Docker, puoi avviare l'intero stack del backend (inclusi PostgreSQL, Redis, Celery, e Flower per il monitoraggio dei task) con un singolo comando:
```bash
cd backend
docker-compose up --build
```
Una volta avviato, i servizi saranno disponibili ai seguenti indirizzi:
- API Backend FastAPI: `http://localhost:8000`
- Documentazione API Swagger: `http://localhost:8000/docs`
- Monitoraggio Task Celery (Flower): `http://localhost:5555`

Il container di FastAPI eseguirà automaticamente l'upgrade del database tramite Alembic all'avvio.

---

### Esecuzione Manuale (Componenti Singoli)

#### 1. Avvia Ollama in locale
Assicurati che Ollama sia in esecuzione sulla porta standard `11434` e che sia presente il modello predefinito:
```bash
ollama run llama3
```

#### 2. Avviare i database locali
PostgreSQL deve essere attivo sulla porta `5432` con un database denominato `hatsune_assistant`. Redis deve essere attivo sulla porta `6379`.
- Windows (Postgres e Redis via WSL):
  ```bash
  sudo service postgresql start
  sudo service redis-server start
  ```
- macOS:
  ```bash
  brew services start postgresql
  brew services start redis
  ```

#### 3. Configurare ed Avviare il Backend Python
Entra nella cartella `backend` e configura l'ambiente virtuale:
```bash
cd backend
python -m venv venv

# Attivazione dell'ambiente virtuale:
# Windows (PowerShell): .\venv\Scripts\Activate.ps1
# macOS/Linux: source venv/bin/activate

# Installazione dipendenze:
pip install -r requirements.txt
```

Esegui le migrazioni di Alembic per preparare lo schema delle tabelle nel database PostgreSQL:
```bash
alembic upgrade head
```

Avvia i tre componenti del backend in terminali separati (assicurandoti che l'ambiente virtuale sia attivo in ciascuno):

**Server API FastAPI**:
```bash
uvicorn app.main:app --reload
```

**Worker Celery**:
```bash
celery -A app.celery_app worker --loglevel=info
```
*(Nota per Windows: se riscontri problemi di concorrenza, aggiungi l'opzione `-P solo`)*

**Celery Beat (Pianificatore)**:
```bash
celery -A app.celery_app beat --loglevel=info
```

#### 4. Avvia il Frontend Flutter
Apri un terminale nella cartella radice del progetto:
```bash
# Scarica le dipendenze
flutter pub get

# Avvia l'analisi statica
flutter analyze

# Avvia l'applicazione
flutter run
```

---

## Struttura delle Cartelle del Progetto

```text
├── backend/                       # Backend FastAPI, Postgres, Redis e Celery (Python)
│   ├── alembic/                   # Directory di gestione delle migrazioni asincrone
│   │   ├── versions/              # Script di migrazione generati
│   │   └── env.py                 # Configurazione dell'ambiente di migrazione
│   ├── app/
│   │   ├── api/                   # Router e endpoint (/chat, /conversations, /models, /health, /tts)
│   │   ├── core/                  # Config, database core, client Redis ed eccezioni
│   │   ├── db/
│   │   │   ├── base.py            # Classe Base dichiarativa di SQLAlchemy
│   │   │   ├── models/            # Modelli ORM (conversation, message, summary, topic, setting)
│   │   │   └── repositories/      # Layer repository per l'interazione persistente Postgres
│   │   ├── schemas/               # Schemi Pydantic per validazione dati
│   │   ├── services/              # Servizio Ollama, TTSService, cache e memoria
│   │   ├── tasks/                 # Task Celery asincroni e periodici
│   │   ├── celery_app.py          # Configurazione dell'applicazione Celery e scheduler
│   │   └── main.py                # Entrypoint principale di FastAPI
│   ├── bin/piper/                 # Binario piper.exe e modelli ONNX (auto-scaricati)
│   ├── alembic.ini                # File di configurazione CLI di Alembic
│   ├── Dockerfile                 # Dockerfile per il build del container backend/worker
│   ├── docker-compose.yml         # Composizione per avvio di Postgres, Redis, FastAPI, Celery e Flower
│   ├── requirements.txt           # Dipendenze Python (FastAPI, SQLAlchemy, asyncpg, Alembic, Redis, Celery)
│   └── README.md                  # Documentazione specifica del backend
│
├── lib/                           # Frontend (Flutter)
│   ├── core/
│   │   ├── design_system/         # Colori cyberpunk, spacing e temi
│   │   ├── responsive/            # Rilevamento dei breakpoint dello schermo
│   │   ├── services/              # Client HTTP verso il backend FastAPI
│   │   └── state/                 # Gestore del cambiamento di stato e pose 3D
│   ├── features/
│   │   ├── home/                  # Dashboard principale e stato sistema
│   │   ├── chat/                  # Widget chat, messaggi e input bar
│   │   ├── models/                # Elenco e picker dei modelli attivi
│   │   └── settings/              # Schermata di configurazione dei parametri
│   ├── shared/
│   │   └── widgets/               # Shell responsive, top bar e visualizzatore 3D
│   └── main.dart                  # Entry point dell'applicazione Flutter
```

---

*Hatsune Miku è un marchio registrato di Crypton Future Media, INC. Sviluppato da biagigio.*
