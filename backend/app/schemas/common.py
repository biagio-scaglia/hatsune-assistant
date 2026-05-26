from pydantic import BaseModel, Field

class StandardResponse(BaseModel):
    """
    Schema standard per risposte di conferma di operazioni (es. cancellazioni, refresh).
    """
    success: bool = Field(..., description="Indica se l'operazione è andata a buon fine")
    message: str = Field(..., description="Messaggio descrittivo sull'esito")
