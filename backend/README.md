# Hatsune Assistant AI Backend

Questo è il backend di servizio in Python (FastAPI) per **Hatsune Assistant**. Funge da bridge (ponte) sicuro e scalabile tra l'applicazione client in Flutter e le API locali/remote di Ollama, integrando ora la sintesi vocale locale tramite **Kokoro TTS**.

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

## Integrazione Kokoro TTS Locale (Opzionale)

Il backend supporta la sintesi vocale locale di alta qualità tramite la libreria **Kokoro TTS**. Tuttavia, a causa delle dipendenze di compilazione C++ (come `spacy`) e della compatibilità di Python 3.14+ su Windows, il servizio Kokoro reale è **disattivato di default** per garantire un avvio privo di errori.

### 1. Avvio Rapido (Modalità Fallback - Predefinita)
All'avvio tramite `start.bat`, il backend si avvierà automaticamente in **Modalità Fallback (sintesi sinusoidale interna)**:
- **Nessuna dipendenza pesante da installare**: non richiede compilatori C++, CUDA, PyTorch o pacchetti esterni.
- **Funziona al 100% su qualsiasi versione di Python (compreso Python 3.14+)**.
- **Genera file WAV reali**: produce dei segnali sinusoidali cyber modulati in frequenza in base alla lunghezza del testo. Questo consente al client Flutter di ricevere comunque gli URL audio, simulando perfettamente il parlato e testando l'animazione di Miku senza errori di build.

### 2. Abilitare Kokoro TTS Reale (Opzionale)
Se desideri attivare la sintesi vocale reale generata da Kokoro TTS locale:
1. Assicurati di utilizzare una versione di Python supportata (consigliato **Python 3.10 - 3.13**).
2. Installa le dipendenze aggiuntive:
   ```bash
   pip install -r requirements-tts.txt
   ```
   *(Nota: Se riscontri errori di build su Windows per `spacy`, dovrai installare i build tools di Visual Studio C++ sul tuo PC).*
3. Al primo utilizzo di Kokoro, la libreria scaricherà automaticamente il modello ONNX (`kokoro-v0_19.onnx`) e le voci in locale.

---

## Configurazione Rapida

### 1. File delle variabili d'ambiente (.env)
Il file `.env` contiene le chiavi di configurazione per Ollama, la sintesi vocale, i timeout e i limiti di sicurezza:
```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development

# Configurazione TTS locale
TTS_PROVIDER=kokoro
TTS_DEFAULT_VOICE=af_heart
TTS_DEFAULT_SPEED=1.0
TTS_DEFAULT_LANG=a

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
*(Nota: `TTS_DEFAULT_LANG` accetta `a` per inglese US, `b` per inglese UK, `i` per italiano, `j` per giapponese)*.

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
       "voice": "af_heart",
       "speed": 1.0
     }'
```
*Risposta di esempio:*
```json
{
  "success": true,
  "audio_url": "http://127.0.0.1:8000/static/generated_audio/audio_9a7fd...wav",
  "text": "Ciao! Sono Hatsune Miku, la tua assistente vocale.",
  "voice": "af_heart",
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
3. **Concorrenza Non-Blocking**: La sintesi vocale (Kokoro o Fallback sinusoidale) è CPU-bound. Viene delegata a un **Thread Pool separato** (`run_in_threadpool`), evitando di bloccare l'Event Loop di FastAPI.
4. **Validazione Rigida degli Input**: Pydantic convalida che i messaggi di chat non superino i `MAX_INPUT_CHARS` (2000 caratteri), lo storico non contenga troppi messaggi, e i parametri TTS (velocità e formato nome voce) siano conformi.

---

## Come Testare Limiti, Timeout e Validazioni

### 1. Testare il Rate Limiting (Blocco 429)
Invia più richieste rapide consecutive a `/api/v1/tts` o `/api/v1/chat`:
```bash
for ($i=1; $i -le 10; $i++) { Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/tts" -Method Post -ContentType "application/json" -Body '{"text": "Test"}' }
```
Dovresti ricevere un errore `429` strutturato così:
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Troppe richieste inviate. Riprova più tardi. Dettaglio: 5 per 1 minute",
    "request_id": "abc123xx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

### 2. Testare la Validazione degli Input (Blocco 400)
Invia un testo di chat vuoto o che supera i 2000 caratteri:
```bash
curl -X POST http://127.0.0.1:8000/api/v1/chat \
     -H "Content-Type: application/json" \
     -d '{"messages": [{"role": "user", "content": " "}]}'
```
Risposta attesa:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Errore di validazione: body -> messages -> 0 -> content: Il contenuto del messaggio non può essere vuoto."
  }
}
```

### 3. Testare i Timeout (Blocco 504)
1. Modifica temporaneamente nel file `.env` il valore `REQUEST_TIMEOUT_SECONDS=0.01`.
2. Riavvia il server ed esegui una chat.
3. Riceverai un errore `504 Gateway Timeout` con il codice `OLLAMA_TIMEOUT`.

