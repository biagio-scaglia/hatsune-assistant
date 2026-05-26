# 🌟 Hatsune Assistant 🌟

> Un assistente alla programmazione interattivo sviluppato in Flutter, con Hatsune Miku come presenza 3D animata collegata a un backend asincrono in Python (FastAPI) connesso a modelli LLM Ollama locali e in Cloud.
> Realizzato con 🩵 da **biagigio**.

---

## 📸 Panoramica del Progetto

Hatsune Assistant unisce l'estetica cyberpunk di Hatsune Miku con una UI scura, moderna ed estremamente responsive progettata per sviluppatori. L'applicazione si appoggia a un backend asincrono in Python che fa da ponte (bridge) verso un'istanza locale di Ollama ed è in grado di inviare prompt, gestire lo streaming delle risposte, configurare i parametri e caricare i modelli installati, integrando al contempo un modello 3D interattivo che reagisce in tempo reale alle interazioni della chat.

### 🩵 Stati e Pose della Miku 3D
L'avatar 3D cambia posa a seconda dello stato di elaborazione dell'assistente:
- **Idle** (`idle.glb`): Stato di riposo/attesa predefinito (con auto-rotazione attiva).
- **Thinking** (`thinking.glb`): Miku si concentra mentre il backend e Ollama elaborano la risposta.
- **Talking** (`talking.glb`): Miku parla ed espone l'output testuale generato.
- **Victory** (`victory.glb`): Miku festeggia quando riceve complimenti o riscontri positivi (es. scrivendo *"grazie"*, *"bella risposta"*, *"ottimo"*, *"brava"*, *"perfetto"* nella chat), per poi tornare automaticamente in stato Idle dopo 5 secondi.

---

## 🚀 Funzionalità Principali

- **Architettura Client-Server**:
  - **FastAPI Python Backend**: Il frontend Flutter comunica con un backend in Python asincrono che funge da bridge sicuro verso Ollama, ottimizzando le performance ed offrendo una base estendibile per provider multipli (OpenAI, Anthropic).
  - **Health Check & Diagnostica**: Rilevamento dello stato di salute del server e della raggiungibilità di Ollama (`GET /api/v1/health`).
  - **Elenco Modelli**: Caricamento dinamico dei modelli installati localmente (`GET /api/v1/models`).
  - **Chat Reale & Streaming SSE**: Supporto completo per risposte standard JSON (`POST /api/v1/chat`) e streaming progressivo delle parole in tempo reale tramite Server-Sent Events (`POST /api/v1/chat/stream`).
  - **Configurazione Centralizzata**: Gestione dinamica dell'indirizzo host e delle chiavi da file `.env`.
- **Layout Responsive Premium**:
  - **Desktop/Tablet**: Split-screen con barra di navigazione laterale (`NavigationRail`) e visualizzatore Miku 3D persistente sulla destra.
  - **Mobile**: Navigazione inferiore (`NavigationBar`) e visualizzatore Miku 3D posizionato in alto, che si nasconde intelligentemente per lasciare il 100% dello spazio ai messaggi quando la tastiera virtuale è aperta.
- **Design System Cyberpunk**: Colori antracite, cyan Miku `#39C5BB` e rosa neon `#FF6B9D`, arricchiti da pannelli con effetto Glassmorphism e glow attivi sul focus dei campi.

---

## 📦 Modelli 3D (glTF/GLB)

I file 3D dell'assistente sono inclusi localmente nel progetto. Puoi visualizzarli ed orbitarli in 3D nativo direttamente su GitHub ai seguenti link:

* 🩵 [Visualizza Modello 3D - Idle (idle.glb)](assets/models/idle.glb)
* 🩵 [Visualizza Modello 3D - Thinking (thinking.glb)](assets/models/thinking.glb)
* 🩵 [Visualizza Modello 3D - Talking (talking.glb)](assets/models/talking.glb)
* 🩵 [Visualizza Modello 3D - Victory (victory.glb)](assets/models/victory.glb)

---

## 🛠️ Stack Tecnologico & Dipendenze

### Frontend (Flutter)
- **Linguaggio**: Dart
- **Framework**: Flutter (Material 3)
- **Dipendenze Chiave**:
  - `model_viewer_plus`: rendering 3D interattivo dei file GLB.
  - `http`: per le chiamate API REST verso il backend FastAPI.
  - `google_fonts`: per i font *Rajdhani* (titoli futuristici) e *Inter* (corpo del testo).

### Backend (Python)
- **Linguaggio**: Python 3.11+
- **Framework**: FastAPI & Uvicorn (server asincrono)
- **Dipendenze Chiave**:
  - `httpx`: per le chiamate asincrone non-blocking a Ollama.
  - `pydantic` & `pydantic-settings`: per la validazione rigorosa dei modelli di dati e delle variabili d'ambiente.

---

## 🚀 Installazione ed Esecuzione

Il progetto richiede l'esecuzione del backend FastAPI (ponte) e del frontend Flutter.

### 1. Avvia Ollama in locale
Assicurati che Ollama sia in esecuzione sulla porta standard `11434` e che sia presente almeno un modello (es. `llama3`):
```bash
ollama run llama3
```

### 2. Avvia il Backend Python (FastAPI)
Entra nella cartella `backend`, crea un ambiente virtuale ed avvia il server di sviluppo:
```bash
cd backend
python -m venv venv

# Attiva l'ambiente virtuale
# Su Windows (PowerShell): .\venv\Scripts\Activate.ps1
# Su macOS/Linux: source venv/bin/activate

# Installa le dipendenze
pip install -r requirements.txt

# Avvia il server
uvicorn app.main:app --reload
```
Il backend sarà avviato all'indirizzo `http://127.0.0.1:8000`. Puoi esplorare la documentazione interattiva Swagger su `http://127.0.0.1:8000/docs`.

### 3. Avvia il Frontend Flutter
Apri una nuova finestra di terminale nella cartella radice del progetto:
```bash
# Scarica le dipendenze
flutter pub get

# Avvia l'analisi statica (0 errori o warning)
flutter analyze

# Avvia i test unitari e di widget
flutter test

# Avvia l'applicazione (ad esempio su Chrome, Desktop o Emulatore)
flutter run
```

---

## 📁 Struttura delle Cartelle del Progetto

```text
├── backend/                       # Backend FastAPI (Python)
│   ├── app/
│   │   ├── api/                   # Router e endpoint (/chat, /models, /health)
│   │   ├── core/                  # Config, logger, eccezioni e handler
│   │   ├── schemas/               # Schemi Pydantic per validazione dati
│   │   └── services/              # Servizio Ollama (con AsyncClient httpx)
│   ├── requirements.txt           # Dipendenze Python
│   └── README.md                  # Manuale specifico del backend
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
│   │   └── settings/              # Impostazione del server URL
│   ├── shared/
│   │   └── widgets/               # Shell responsive, top bar e 3D viewer
│   └── main.dart                  # Entry point dell'app
```

---

*Hatsune Miku è un marchio registrato di Crypton Future Media, INC. Sviluppato da biagigio.*
