from slowapi import Limiter
from slowapi.util import get_remote_address

# Inizializziamo il Limiter globale usando l'IP del client come chiave di tracciamento
limiter = Limiter(key_func=get_remote_address)
