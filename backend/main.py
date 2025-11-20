from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Literal
from datetime import datetime
import uvicorn

app = FastAPI(title="Spam Dashboard API", version="1.0.0")

# CORS middleware per permettere richieste dal frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In produzione, specifica il dominio del frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelli Pydantic per validazione
class EmailItem(BaseModel):
    mittente: str = Field(..., description="Indirizzo o nome del mittente dell'email")
    oggetto: str = Field(..., description="L'oggetto dell'email")
    riassunto: str = Field(..., description="Breve riassunto del contenuto dell'email")
    rischio: Literal["alto", "medio", "basso"] = Field(..., description="Valutazione del rischio della mail")

class EmailData(BaseModel):
    emails: List[EmailItem] = Field(..., description="Lista delle email analizzate e strutturate")

# Storage in memoria (in produzione usa un database)
email_storage: List[dict] = []

@app.get("/")
async def root():
    return {"message": "Spam Dashboard API", "status": "running"}

@app.post("/api/emails", response_model=dict)
async def receive_emails(data: EmailData):
    """
    Endpoint per ricevere email analizzate da Flowise.
    Questo è l'endpoint da configurare nel nodo HTTP di Flowise.
    """
    try:
        # Aggiungi timestamp a ogni email
        emails_with_timestamp = []
        timestamp = datetime.now().isoformat()
        
        for email in data.emails:
            email_dict = email.model_dump()
            email_dict["timestamp"] = timestamp
            emails_with_timestamp.append(email_dict)
        
        # Salva in memoria (prepend per avere le più recenti prima)
        email_storage[:0] = emails_with_timestamp
        
        return {
            "status": "success",
            "message": f"Ricevute {len(emails_with_timestamp)} email",
            "count": len(emails_with_timestamp)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Errore nel processare le email: {str(e)}")

@app.get("/api/emails", response_model=dict)
async def get_emails():
    """
    Endpoint per recuperare tutte le email salvate.
    Usato dalla dashboard frontend.
    """
    return {
        "emails": email_storage,
        "count": len(email_storage)
    }

@app.delete("/api/emails")
async def clear_emails():
    """
    Endpoint per cancellare tutte le email salvate.
    """
    global email_storage
    count = len(email_storage)
    email_storage = []
    return {
        "status": "success",
        "message": f"Eliminate {count} email"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

