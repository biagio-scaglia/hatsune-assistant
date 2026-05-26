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
Il file `.env` contiene le chiavi di configurazione per Ollama e per la sintesi vocale:
```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development

# Configurazione TTS locale
TTS_PROVIDER=kokoro
TTS_DEFAULT_VOICE=af_heart
TTS_DEFAULT_SPEED=1.0
TTS_DEFAULT_LANG=a
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
