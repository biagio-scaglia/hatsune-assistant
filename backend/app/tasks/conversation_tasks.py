import json
import logging
import asyncio
from ..celery_app import celery_app
from ..services.ollama_service import OllamaService
from ..services.cache_service import CacheService

logger = logging.getLogger(__name__)

def run_async(coro):
    """Esegue coroutine asincrone in thread sincroni."""
    try:
        return asyncio.run(coro)
    except RuntimeError:
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(coro)

@celery_app.task(name="app.tasks.conversation_tasks.generate_summary_and_topics_task")
def generate_summary_and_topics_task(messages: list, conversation_id: str, model: str):
    """
    Task Celery per generare in background il riassunto e i topic principali di una conversazione.
    Interroga Ollama con un prompt strutturato e salva i risultati in Redis.
    """
    logger.info(f"[CONV TASK] Inizio elaborazione memoria per conversazione: {conversation_id}")
    
    # Costruiamo la trascrizione leggibile per il modello
    chat_history_text = ""
    for msg in messages:
        role = "Utente" if msg["role"] == "user" else "Assistente"
        chat_history_text += f"{role}: {msg['content']}\n"

    # Prompt strutturato per richiedere JSON nativo
    prompt = (
        "Analizza la seguente conversazione tra l'Utente e l'Assistente Hatsune Miku.\n"
        "Genera un riassunto compatto (massimo 2-3 frasi) e identifica fino a 3 argomenti/parole chiave principali.\n"
        "Devi rispondere esclusivamente in formato JSON valido, senza testo prima o dopo, con questa struttura:\n"
        '{\n  "summary": "riassunto qui",\n  "topics": "tag1, tag2, tag3"\n}\n\n'
        f"Conversazione:\n{chat_history_text}"
    )

    try:
        ollama_service = OllamaService()
        
        # Richiede a Ollama la sintesi con temperatura bassa per mantenere la precisione del JSON
        response_data = run_async(
            ollama_service.chat(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2
            )
        )
        
        response_text = response_data.get("message", {}).get("content", "").strip()
        
        # Estrattore del blocco JSON qualora il modello introducesse frasi aggiuntive
        if "{" in response_text and "}" in response_text:
            start_idx = response_text.find("{")
            end_idx = response_text.rfind("}") + 1
            json_str = response_text[start_idx:end_idx]
        else:
            json_str = response_text

        # Parsing e salvataggio in cache
        data = json.loads(json_str)
        summary = data.get("summary", "").strip()
        topics = data.get("topics", "").strip()

        if summary:
            summary_key = f"conv:{conversation_id}:summary"
            topics_key = f"conv:{conversation_id}:topics"
            
            # Salvataggio con validità di 7 giorni
            CacheService.set(summary_key, summary, ttl=604800)
            CacheService.set(topics_key, topics, ttl=604800)
            
            logger.info(f"[CONV TASK] Memoria della conversazione {conversation_id} aggiornata in Redis.")
            logger.debug(f"[CONV TASK] Summary: {summary} | Topics: {topics}")
        else:
            logger.warning("[CONV TASK] Il riassunto generato risulta vuoto.")
            
    except json.JSONDecodeError as jde:
        logger.error(f"[CONV TASK] Errore di parsing JSON del riassunto: {jde}. Risposta del modello: {response_text}")
    except Exception as e:
        logger.error(f"[CONV TASK] Errore imprevisto durante l'elaborazione dei task di memoria: {e}")
