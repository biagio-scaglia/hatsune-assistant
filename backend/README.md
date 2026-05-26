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

## Integrazione Kokoro TTS Locale

Il backend supporta la sintesi vocale asincrona locale tramite **Kokoro TTS** (modello da 82M parametri ad altissima qualità).

### 1. Installazione automatica delle dipendenze audio
Per attivare il TTS locale, installa le dipendenze aggiuntive incluse nel file `requirements.txt`:
```bash
pip install -r requirements.txt
```

### 2. Modelli e File delle Voci (Kokoro automatico)
La libreria `kokoro` scaricherà automaticamente il checkpoint ONNX (`kokoro-v0_19.onnx`) e il dizionario delle voci (`voices.json`) al primo avvio all'interno della cache utente (es. in `~/.num2words` o cartelle cache di Hugging Face).

### 3. Modalità Fallback (Senza configurazione hardware)
Se non hai una GPU CUDA pronta o riscontri problemi nell'installazione delle librerie native di PyTorch/ONNX, il backend **non andrà in errore**. 
Il sistema si avvierà automaticamente in **modalità Fallback (Beep sinusoidale)**, generando file WAV validi contenenti impulsi acustici cyber con inviluppo e modulazione. Questo garantisce che gli endpoint `/tts` e `/chat-with-tts` rimangano operativi al 100% per testare il flusso UI su Flutter.

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
