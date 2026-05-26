# Hatsune Assistant AI Backend

Questo è il backend di servizio in Python (FastAPI) per **Hatsune Assistant**. Funge da bridge (ponte) sicuro e scalabile tra l'applicazione client in Flutter e le API locali/remote di Ollama.

## Funzionalità principali
1. **Health Check (`/api/v1/health`)**: Verifica lo stato del backend e la connettività con Ollama.
2. **Gestione Modelli (`/api/v1/models` e `/api/v1/models/default`)**: Elenca e seleziona i LLM disponibili.
3. **Chat sincrona (`/api/v1/chat`)**: Endpoint di chat standard con risposta JSON per Flutter.
4. **Chat streaming (`/api/v1/chat/stream`)**: Risposta progressiva in tempo reale tramite Server-Sent Events (SSE).
5. **CORS Abilitato**: Configurato per consentire lo sviluppo locale su Web, Mobile e Desktop.
6. **Architettura Scalabile**: Facilmente estendibile a provider cloud esterni (OpenAI, Anthropic).

---

## Prerequisiti
- **Python 3.11** o superiore installato sul computer.
- **Ollama** installato e avviato sul proprio PC.

---

## Configurazione rapida

### 1. Avviare Ollama
Assicurati che Ollama sia attivo sulla porta di default `11434`.
Per verificare se è attivo, apri un browser su:
```
http://localhost:11434
```

### 2. Creare un ambiente virtuale (venv)
Dalla cartella `backend`, crea un ambiente virtuale Python per isolare le dipendenze:

**Su Windows (PowerShell):**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

**Su macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Installare le dipendenze
Installa i pacchetti richiesti presenti nel file `requirements.txt`:
```bash
pip install -r requirements.txt
```

### 4. Configurare le variabili d'ambiente
Crea un file `.env` partendo da `.env.example` (il file `.env` con i parametri standard è già stato creato automaticamente nella cartella):
```bash
cp .env.example .env
```
Contenuto tipico del file `.env`:
```ini
OLLAMA_BASE_URL=http://localhost:11434
DEFAULT_MODEL=llama3:latest
APP_ENV=development
```

---

## Avviare il Backend

Avvia il server di sviluppo asincrono con **Uvicorn**:
```bash
uvicorn app.main:app --reload
```
Il backend sarà avviato all'indirizzo: `http://127.0.0.1:8000`

La documentazione interattiva Swagger è disponibile su: `http://127.0.0.1:8000/docs`

---

## Esempi di Chiamate API (Test)

Puoi testare le API aperte tramite `curl` da terminale o tramite strumenti come Postman/Insomnia.

### 1. Health Check
```bash
curl http://127.0.0.1:8000/api/v1/health
```

### 2. Elenco Modelli
```bash
curl http://127.0.0.1:8000/api/v1/models
```

### 3. Chat Sincrona (JSON)
```bash
curl -X POST http://127.0.0.1:8000/api/v1/chat \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama3:latest",
       "messages": [
         {"role": "user", "content": "Ciao Miku! Scrivi un print in Dart."}
       ]
     }'
```

### 4. Chat in Streaming (SSE)
```bash
curl -N -X POST http://127.0.0.1:8000/api/v1/chat/stream \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama3:latest",
       "messages": [
         {"role": "user", "content": "Raccontami una breve barzelletta sui programmatori."}
       ]
     }'
```
*(Il parametro `-N` serve a disabilitare il buffering del terminale per mostrare lo streaming in tempo reale)*.
