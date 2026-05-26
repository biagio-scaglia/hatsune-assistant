import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from .config import settings

logger = logging.getLogger(__name__)

# Configurazione del database asincrono con pool di connessioni ottimizzato
# Usiamo il driver asyncpg per garantire massime performance
try:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False,              # Impostare a True solo per debug delle query SQL
        future=True,
        pool_size=10,            # Numero fisso di connessioni mantenute aperte
        max_overflow=20,         # Connessioni aggiuntive ammesse in caso di picchi
        pool_recycle=1800        # Riciclo connessioni ogni 30 minuti per prevenire timeout di rete
    )
    
    async_session_maker = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False   # Evita refresh inutili di oggetti dopo il commit
    )
except Exception as e:
    logger.critical(f"[DATABASE] Impossibile configurare l'engine SQLAlchemy: {e}")
    raise e

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency per FastAPI. Fornisce una sessione di database asincrona
    che viene aperta all'inizio della richiesta e chiusa automaticamente al termine.
    """
    async with async_session_maker() as session:
        try:
            yield session
        except Exception as e:
            logger.error(f"[DATABASE] Errore durante la sessione, eseguo rollback: {e}")
            await session.rollback()
            raise e
        finally:
            await session.close()
