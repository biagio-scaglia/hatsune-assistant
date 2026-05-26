# Hatsune Assistant AI Backend

Questo è il backend di servizio in Python (FastAPI) per **Hatsune Assistant**. Funge da bridge (ponte) sicuro e scalabile tra l'applicazione client in Flutter e le API locali/remote di Ollama, integrando ora la sintesi vocale locale ad alte prestazioni tramite **Piper TTS**.

## Funzionalità principali
1. **Health Check (`/api/v1/health`)**: Verifica lo stato del backend e la connettività con Ollama.
2. **Gestione Modelli (`/api/v1/models` e `/api/v1/models/default`)**: Elenca e seleziona i LLM disponibili.
3. **Chat sincrona (`/api/v1/chat`)**: Endpoint di chat standard con risposta JSON.
4. **Chat streaming (`/api/v1/chat/stream`)**: Risposta progressiva in tempo reale tramite Server-Sent Events (SSE).
5. **Sintesi Vocale Standalone (`/api/v1/tts`)**: Genera un file WAV a partire da un testo e fornisce un URL statico per la riproduzione.
6. **Pipeline Chat + TTS (`/api/v1/chat-with-tts`)**: Interroga Ollama e converte immediatamente la risposta in audio, restituendo testo ed URL audio in una singola richiesta.
7. **Posa e Parlato coordinati**: I link audio consentono a Flutter di riprodurre la voce e coordinare l'animazione di Miku ("talking" durante la riproduzione).

---

## Prerequisiti
- **Python 3.11** o superiore installato sul computer.
- **Ollama** installato e avviato sul proprio PC.

---

## Integrazione Piper TTS Locale (Zero-Dependency)

Il backend integra **Piper TTS** in locale come motore di sintesi vocale principale. 
Per evitare pesanti compilazioni C++ o problemi di incompatibilità delle librerie ML (PyTorch, ONNX runtime) su Windows con Python 3.14+, il backend utilizza l'eseguibile precompilato ufficiale **Piper standalone (`piper.exe`)**.

### Come funziona il download automatico degli Asset:
Al primo avvio o alla prima chiamata TTS, il backend verificherà ed eventualmente scaricherà in background (senza bloccare l'avvio di FastAPI) i seguenti file nella cartella `backend/bin/piper/`:
1. **Motore Piper**: Scarica `piper_windows_amd64.zip` (da GitHub releases v1.2.0) e lo estrae automaticamente.
2. **Modelli di default**: Scarica da Hugging Face `rhasspy/piper-voices` i file del modello vocale (`.onnx` e `.json`):
   - Per l'italiano: `it_IT-riccardo-x_low` (voce Riccardo, circa 15 MB)
   - Per l'inglese: `en_US-lessac-medium` (voce Lessac, circa 15 MB)

> [!NOTE]
> Fino a quando il download in background non è completato (o in caso di assenza temporanea di connessione internet), il backend genererà automaticamente un **bip sinusoidale modulato (modalità Fallback)**. Questo garantisce che le chiamate API non falliscano mai e il client Flutter possa comunque riprodurre l'audio per testare l'animazione dell'avatar.

### Aggiungere voci personalizzate:
Puoi aggiungere modelli vocali aggiuntivi scaricandoli manualmente dal repository Hugging Face [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices/tree/main).
Inserisci i file `.onnx` e `.json` nella cartella `backend/bin/piper/voices/`. Il nome della voce passato nella richiesta API deve corrispondere esattamente al nome del file (es: `it_IT-paola-medium`). Il backend tenterà di scaricarla automaticamente se non presente localmente!

---

## Configurazione Rapida

### 1. File delle variabili d'ambiente (.env)
Il file `.env` contiene le chiavi di configurazione per Ollama, la sintesi vocale, i timeout e i limiti di sicurezza:
```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development

# Configurazione TTS locale
TTS_PROVIDER=piper
TTS_DEFAULT_VOICE=it_IT-riccardo-x_low
TTS_DEFAULT_SPEED=1.0
TTS_DEFAULT_LANG=it

# Impostazioni specifiche per Piper
# Se lasciati vuoti, verranno scaricati automaticamente i modelli di default
PIPER_MODEL_PATH=
PIPER_CONFIG_PATH=
# Directory per salvare i file audio WAV generati
AUDIO_OUTPUT_DIR=app/static/generated_audio

# Impostazioni di Hardening & Timeout (in secondi)
REQUEST_TIMEOUT_SECONDS=60.0
STREAM_TIMEOUT_SECONDS=90.0

# Rate Limiting (richieste per IP)
RATE_LIMIT_GLOBAL=100/minute
RATE_LIMIT_CHAT=15/minute
RATE_LIMIT_TTS=5/minute
RATE_LIMIT_HEALTH=120/minute

# Validazione Input
MAX_INPUT_CHARS=2000
MAX_CONTEXT_MESSAGES=20

# Sicurezza CORS (* per sviluppo locale, oppure lista di URL esatti)
CORS_ORIGINS=*
```

### 2. Creare un ambiente virtuale (venv)
**Su Windows:**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**Su macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Installare le dipendenze e avviare
Utilizza lo script preconfigurato su Windows per fare tutto in un clic:
```powershell
.\start.bat
```
Oppure manualmente:
```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Il server sarà attivo su `http://127.0.0.1:8000` con documentazione interattiva su `http://127.0.0.1:8000/docs`.

---

## Esempi di Chiamate API per il TTS

### 1. Sintesi Vocale Standalone (`/tts`)
Invia un testo per ricevere il link del file audio generato:
```bash
curl -X POST http://127.0.0.1:8000/api/v1/tts \
     -H "Content-Type: application/json" \
     -d '{
       "text": "Ciao! Sono Hatsune Miku, la tua assistente vocale.",
       "voice": "it_IT-riccardo-x_low",
       "speed": 1.0
     }'
```
*Risposta di esempio:*
```json
{
  "success": true,
  "audio_url": "http://127.0.0.1:8000/static/generated_audio/audio_9a7fd...wav",
  "text": "Ciao! Sono Hatsune Miku, la tua assistente vocale.",
  "voice": "it_IT-riccardo-x_low",
  "speed": 1.0
}
```

### 2. Pipeline Chat con Risposta Vocale (`/chat-with-tts`)
Invia un messaggio per ottenere la risposta del modello LLM in formato testo ed audio coordinati:
```bash
curl -X POST http://127.0.0.1:8000/api/v1/chat-with-tts \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama3:latest",
       "messages": [
         {"role": "user", "content": "Chi sei?"}
       ]
     }'
```
*Risposta di esempio:*
```json
{
  "success": true,
  "message": {
    "role": "assistant",
    "content": "Ciao! Sono Hatsune Miku, il tuo assistente virtuale di programmazione..."
  },
  "model": "llama3:latest",
  "time": "12:56",
  "audio_url": "http://127.0.0.1:8000/static/generated_audio/audio_2f31b...wav",
  "tts_active": true
}
```

---

## Strategia di Gestione dello Spazio Disco (Audio Files)
Il backend implementa un meccanismo automatico di auto-pulizia nel file `app/services/tts_service.py`:
- All'avvio di ogni sintesi, rimuove i file `.wav` più vecchi di 10 minuti.
- Limita il numero massimo di file audio conservati nella cartella `static/generated_audio` a un tetto di 50. I file in eccesso vengono eliminati partendo dal più vecchio.

---

## Hardening, Rate Limiting & Concorrenza

Il backend implementa diverse misure di sicurezza industriale per prevenire abusi e garantire la fluidità del server:
1. **Rate Limiting Globale e Specifico**: Ogni richiesta viene tracciata in base all'IP del client. Richieste ripetute e veloci restituiranno un errore `429 Too Many Requests`.
2. **Correlation ID (`X-Request-ID`)**: Ogni chiamata riceve un UUID univoco propagato sia nei log del server che nell'header della risposta HTTP. Questo rende il tracciamento degli errori immediato.
3. **Concorrenza Non-Blocking**: La sintesi vocale (Piper) è CPU-bound. Viene delegata a un **Thread Pool separato** (`run_in_threadpool`), evitando di bloccare l'Event Loop di FastAPI.
4. **Validazione Rigida degli Input**: Pydantic convalida che i messaggi di chat non superino i `MAX_INPUT_CHARS` (2000 caratteri), lo storico non contenga troppi messaggi, e i parametri TTS (velocità e formato nome voce) siano conformi.
