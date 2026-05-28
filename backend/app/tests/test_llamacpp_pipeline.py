import os
import sys
import asyncio
import time
import json

# Aggiunge il path della radice del backend per consentire gli import
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.core.config import settings
from app.services.llm_service import LLMService

async def test_non_streaming(llm_service: LLMService, model: str):
    print("\n--- TEST CHAT (NON-STREAMING) ---")
    messages = [
        {"role": "system", "content": "Sei Hatsune Miku, rispondi brevemente in italiano."},
        {"role": "user", "content": "Ciao! Come ti chiami?"}
    ]
    
    start_time = time.time()
    try:
        response = await llm_service.chat(
            model=model,
            messages=messages,
            temperature=0.7
        )
        latency = time.time() - start_time
        print(f"Risposta ricevuta in {latency:.3f} secondi.")
        print(f"Risposta di Miku: \"{response.get('message', {}).get('content', '')}\"")
        print(f"Dettagli di risposta: {json.dumps(response, indent=2)}")
        return True
    except Exception as e:
        print(f"Errore durante la chat non-streaming: {e}", file=sys.stderr)
        return False

async def test_streaming(llm_service: LLMService, model: str):
    print("\n--- TEST CHAT (STREAMING) ---")
    messages = [
        {"role": "system", "content": "Sei Hatsune Miku, rispondi brevemente in italiano."},
        {"role": "user", "content": "Qual è il tuo colore preferito?"}
    ]
    
    start_time = time.time()
    first_token_time = None
    chunks_received = 0
    full_content = ""
    
    try:
        generator = await llm_service.chat_stream(
            model=model,
            messages=messages,
            temperature=0.7
        )
        
        print("Miku sta scrivendo: ", end="", flush=True)
        async for chunk in generator:
            if not chunk.startswith("data: "):
                continue
            
            data_str = chunk[6:].strip()
            if not data_str:
                continue
                
            try:
                data_json = json.loads(data_str)
                content = data_json.get("content", "")
                
                if content:
                    if first_token_time is None:
                        first_token_time = time.time() - start_time
                    full_content += content
                    print(content, end="", flush=True)
                    chunks_received += 1
                
                if data_json.get("done", False):
                    break
            except json.JSONDecodeError:
                continue
        
        total_time = time.time() - start_time
        print("\n")
        print(f"Primo token ricevuto in: {first_token_time:.3f} secondi (Time-to-First-Token).")
        print(f"Tempo totale di streaming: {total_time:.3f} secondi per {chunks_received} chunk.")
        print(f"Risposta completa: \"{full_content}\"")
        return True
    except Exception as e:
        print(f"\nErrore durante lo streaming: {e}", file=sys.stderr)
        return False

async def main():
    print("==================================================")
    print("  TEST PIPELINE LLM SERVICE (Ollama / llama.cpp)  ")
    print("==================================================")
    print(f"Provider configurato: {settings.LLM_PROVIDER}")
    
    active_url = settings.LLAMACPP_BASE_URL if settings.LLM_PROVIDER == "llamacpp" else settings.OLLAMA_BASE_URL
    print(f"URL Provider: {active_url}")
    print(f"Modello di default: {settings.DEFAULT_MODEL}")
    print("--------------------------------------------------")

    llm_service = LLMService()

    # 1. Verifica Health
    print("1. Verifica dello stato di salute (Health Check)...")
    health = await llm_service.check_health()
    print(f"Risultato Health Check: {json.dumps(health, indent=2)}")
    
    if not health.get("connected", False):
        print(f"\n[ATTENZIONE] Il provider {settings.LLM_PROVIDER} non risponde. Assicurati che sia attivo su {active_url}.", file=sys.stderr)
        # Non usciamo per permettere di vedere comunque l'errore sollevato dalle chiamate successive
    
    # 2. Caricamento Modelli
    print("\n2. Recupero dei modelli disponibili...")
    try:
        models = await llm_service.fetch_models()
        print(f"Trovati {len(models)} modelli:")
        for m in models:
            print(f" - ID: {m['id']} | Provider: {m['provider']} | Size: {m['size']}")
    except Exception as e:
        print(f"Errore nel recupero modelli: {e}", file=sys.stderr)

    # 3. Test Chat
    model_to_use = settings.DEFAULT_MODEL
    ok_non_stream = await test_non_streaming(llm_service, model_to_use)
    ok_stream = await test_streaming(llm_service, model_to_use)

    print("\n==================================================")
    if ok_non_stream and ok_stream:
        print("  [OK] TUTTI I TEST SONO STATI SUPERATI CON SUCCESSO!  ")
    else:
        print("  [ERRORE] ALCUNI TEST SONO FALLITI. CONTROLLA I LOG.  ")
    print("==================================================")

if __name__ == "__main__":
    asyncio.run(main())
