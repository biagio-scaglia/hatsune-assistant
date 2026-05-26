from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    """
    Classe base dichiarativa di SQLAlchemy 2.0 per definire la struttura delle tabelle.
    Definita separatamente per evitare import circolari nei modelli ORM.
    """
    pass
