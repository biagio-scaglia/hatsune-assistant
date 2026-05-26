from .base_class import Base

# Importa tutti i modelli così che siano registrati su Base.metadata
from .models.conversation import Conversation
from .models.message import Message
from .models.summary import ConversationSummary
from .models.topic import ConversationTopic
from .models.setting import AppSetting

