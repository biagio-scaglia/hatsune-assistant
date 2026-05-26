from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    """
    Classe base dichiarativa per tutti i modelli ORM di SQLAlchemy 2.0.
    Consente di centralizzare i metadata per la generazione automatica delle migrazioni via Alembic.
    """
    pass

# Importa tutti i modelli così che siano registrati su Base.metadata
from .models.conversation import Conversation
from .models.message import Message
from .models.summary import ConversationSummary
from .models.topic import ConversationTopic
from .models.setting import AppSetting

