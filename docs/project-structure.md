# Struttura del Progetto (Monorepo)

Questo documento illustra l'organizzazione strutturale del repository Hatsune Assistant dopo la riorganizzazione in monorepo, delineando le responsabilità di ciascuna cartella e file.

## Schema Generale delle Cartelle

```text
hatsune-assistant/
├── app/
│   └── flutter_app/               # Applicazione client (Flutter)
│       ├── android/               # Piattaforma Android
│       ├── ios/                   # Piattaforma iOS
│       ├── lib/                   # Codice sorgente Dart
│       │   ├── core/              # Config, design system, servizi e state management
│       │   ├── features/          # Funzionalità dell'app (chat, voice_call, settings, ecc.)
│       │   ├── shared/            # Widget condivisi
│       │   └── main.dart          # Entry point del client
│       ├── assets/                # Modelli 3D GLB ed immagini
│       └── pubspec.yaml           # Dipendenze Flutter
│
├── backend/                       # Server asincrono (FastAPI, Redis, Celery, Postgres)
│   ├── alembic/                   # Migrazioni asincrone del database SQL
│   ├── app/
│   │   ├── api/                   # Endpoint delle rotte (chat, health, models, voice, tts)
│   │   ├── core/                  # Database, Redis client, rate limit ed eccezioni
│   │   ├── db/                    # Modelli SQLAlchemy e layer Repository (CRUD)
│   │   ├── providers/             # Astrazione LLM (Ollama e llama.cpp)
│   │   ├── schemas/               # Validazione dati Pydantic
│   │   ├── services/              # Logica applicativa (TTS, STT, LLM Service, memoria)
│   │   ├── static/                # File statici (compreso audio generato temporaneamente)
│   │   ├── tasks/                 # Task asincroni Celery (summary e manutenzione cache)
│   │   └── main.py                # Entry point principale di FastAPI
│   ├── tests/                     # Test diagnostici (Whisper e llama.cpp pipeline)
│   ├── bin/                       # Binari C++ di Piper TTS e modelli di voce (autogenerati)
│   ├── requirements.txt           # Dipendenze Python
│   ├── .env.example               # Configurazione d'ambiente segnaposto
│   └── docker-compose.yml         # Composizione dei servizi per Docker
│
├── docs/                          # Documentazione tecnica ed architetturale
│   └── project-structure.md       # Questo file
│
├── scripts/                       # Script batch di automazione (Windows)
│   ├── bootstrap.bat              # Setup venv, pip install, flutter pub get
│   ├── start_backend.bat          # Avvio di FastAPI con migrazioni preventive
│   ├── start_celery_worker.bat    # Avvio di Celery Worker
│   ├── start_celery_beat.bat      # Avvio di Celery Beat (scheduler)
│   └── cleanup.bat                # Pulizia file temporanei, cache e WAV
│
├── .gitignore                     # Configurazione di esclusione git globale
└── README.md                      # Manuale d'uso e guida all'avvio rapido del progetto
```

---

## Dettaglio dei Componenti

### 1. Frontend (`app/flutter_app/`)
Contiene il codice dell'app client in Flutter, strutturato per feature:
- `lib/core/state/assistant_state.dart`: Gestisce lo stato globale del client, compresa la selezione del modello, il comportamento della Miku 3D ed il trigger delle chiamate.
- `lib/features/voice_call/`: Interfaccia utente ed animazioni della modalità Chiamata Vocale.
- `lib/shared/widgets/miku_3d_viewer.dart`: Widget per il rendering ed il cambio posa reattivo dell'avatar GLB 3D.

### 2. Backend (`backend/`)
Il motore centrale del progetto scritto in Python.
- `app/providers/`: Implementa l'interfaccia astratta `BaseLLMProvider` consentendo di scambiare in tempo reale il motore LLM tra Ollama e llama.cpp server, isolando le chiamate HTTP.
- `app/services/conversation_memory_service.py`: Gestisce il prompt in modo che sia compatibile con il prompt caching di llama.cpp server tramite una sliding window a blocchi di 4 messaggi.
- `bin/piper/`: Ospita l'eseguibile portabile C++ `piper.exe` e scarica in modalità pigra i modelli ONNX delle voci italiane (senza pesare sul build di Python).

### 3. Script (`scripts/`)
Progettati per rendere immediato il ciclo di sviluppo locale per sviluppatori Windows:
- **`bootstrap.bat`**: Si occupa di automatizzare le installazioni iniziali di pacchetti Python e Flutter.
- **`cleanup.bat`**: Risolve il problema del accumulo di file WAV temporanei generati durante le prove vocali e pulisce la cache di compilazione.
