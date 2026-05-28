import json
import logging
import asyncio
from ..celery_app import celery_app
from ..services.llm_service import LLMService
from ..services.cache_service import CacheService
from ..core.db import async_session_maker
from ..db.repositories.conversation_repository import ConversationRepository

logger = logging.getLogger(__name__)

def run_async(coro):
    """Helper per eseguire coroutine in thread sincroni."""
    try:
        return asyncio.run(coro)
    except RuntimeError:
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(coro)

@celery_app.task(name="app.tasks.conversation_tasks.generate_summary_and_topics_task")
def generate_summary_and_topics_task(conversation_id: str, model: str):
    """
    Task Celery per generare in background il riassunto e i topic principali di una conversazione.
    Legge la cronologia da PostgreSQL, chiama il provider LLM attivo e persiste i risultati sia su DB che su cache Redis.
    """
    logger.info(f"[CONV TASK] Inizio elaborazione memoria per conversazione: {conversation_id}")
    
    async def _process():
        async with async_session_maker() as session:
            # 1. Recupera la cronologia completa dei messaggi da Postgres
            messages = await ConversationRepository.get_messages(session, conversation_id)
            if not messages:
                logger.warning(f"[CONV TASK] Nessun messaggio trovato nel database per {conversation_id}.")
                return

            # Costruisce la trascrizione testuale leggibile
            chat_history_text = ""
            for msg in messages:
                role = "Utente" if msg.role == "user" else "Assistente"
                chat_history_text += f"{role}: {msg.content}\n"

            # Prompt strutturato
            prompt = (
                "Analizza la seguente conversazione tra l'Utente e l'Assistente Hatsune Miku.\n"
                "Genera un riassunto compatto (massimo 2-3 frasi) e identifica fino a 3 argomenti/parole chiave principali.\n"
                "Devi rispondere esclusivamente in formato JSON valido, senza testo prima o dopo, con questa struttura:\n"
                '{\n  "summary": "riassunto qui",\n  "topics": "tag1, tag2, tag3"\n}\n\n'
                f"Conversazione:\n{chat_history_text}"
            )

            try:
                llm_service = LLMService()
                
                # Chiama il servizio LLM per riassumere
                response_data = await llm_service.chat(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.2
                )
                
                response_text = response_data.get("message", {}).get("content", "").strip()
                
                # Estrae il JSON pulito
                if "{" in response_text and "}" in response_text:
                    start_idx = response_text.find("{")
                    end_idx = response_text.rfind("}") + 1
                    json_str = response_text[start_idx:end_idx]
                else:
                    json_str = response_text

                data = json.loads(json_str)
                summary_text = data.get("summary", "").strip()
                topics_text = data.get("topics", "").strip()

                if summary_text:
                    # 2. Salva in modo persistente su PostgreSQL
                    await ConversationRepository.update_or_create_summary(session, conversation_id, summary_text)
                    
                    topics_list = [t.strip() for t in topics_text.split(",") if t.strip()]
                    await ConversationRepository.update_topics(session, conversation_id, topics_list)
                    
                    # 3. Salva nella cache Redis per letture rapide
                    summary_key = f"conv:{conversation_id}:summary"
                    topics_key = f"conv:{conversation_id}:topics"
                    
                    CacheService.set(summary_key, summary_text, ttl=604800)
                    CacheService.set(topics_key, topics_text, ttl=604800)
                    
                    logger.info(f"[CONV TASK] Memoria della conversazione {conversation_id} salvata correttamente su PostgreSQL e Redis!")
                else:
                    logger.warning("[CONV TASK] Il summary generato è vuoto.")
                    
            except json.JSONDecodeError as jde:
                logger.error(f"[CONV TASK] Errore parsing JSON: {jde}. Risposta di Ollama: {response_text}")
            except Exception as e:
                logger.error(f"[CONV TASK] Errore durante la sintesi o il salvataggio dei dati: {e}")

    # Esegue il flusso asincrono
    run_async(_process())
