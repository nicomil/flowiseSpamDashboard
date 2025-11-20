# Spam Dashboard Flowise

Dashboard per visualizzare e monitorare le email analizzate da Flowise.

## 🚀 Quick Start

### Opzione 1: Docker Compose (Consigliato)

Il modo più semplice per avviare l'applicazione:

```bash
# Build e avvio
docker-compose up -d --build

# Verifica stato
docker-compose ps

# Visualizza log
docker-compose logs -f
```

L'applicazione sarà disponibile su:
- Frontend: `http://localhost`
- Backend API: `http://localhost:8000`
- API via Frontend: `http://localhost/api/emails`

**Comandi utili:**
```bash
make help          # Mostra tutti i comandi disponibili
make up            # Avvia i container
make down          # Ferma i container
make logs          # Mostra i log
make rebuild       # Ricostruisce e riavvia
```

### Opzione 2: Sviluppo Locale

#### Backend (FastAPI)

1. Installa le dipendenze con Poetry:
```bash
poetry install
```

2. Avvia il server:
```bash
poetry run uvicorn backend.main:app --reload --port 8000
```

Il backend sarà disponibile su `http://localhost:8000`

#### Frontend (React + Vite)

1. Installa le dipendenze:
```bash
cd frontend
npm install
```

2. Avvia il server di sviluppo:
```bash
npm run dev
```

Il frontend sarà disponibile su `http://localhost:5173`

## 📡 Configurazione Flowise

### Endpoint da utilizzare

L'endpoint da configurare nel nodo HTTP di Flowise è:
```
POST http://localhost:8000/api/emails
```

Se il backend è su un altro server, sostituisci `localhost:8000` con l'URL corretto.

### Configurazione del Nodo HTTP in Flowise

1. **Aggiungi il nodo HTTP Request** al tuo flow
2. **Configurazione del nodo:**

   **URL:**
   ```
   http://localhost:8000/api/emails
   ```
   (o l'URL del tuo server backend)

   **Method:**
   ```
   POST
   ```

   **Headers:**
   ```
   Content-Type: application/json
   ```

   **Body Type:**
   ```
   JSON
   ```

   **Body (JSON):**
   ```json
   {
     "emails": [
       {
         "mittente": "{{mittente}}",
         "oggetto": "{{oggetto}}",
         "riassunto": "{{riassunto}}",
         "rischio": "{{rischio}}"
       }
     ]
   }
   ```
   
   Oppure, se hai un array di email da inviare:
   ```json
   {
     "emails": {{emails}}
   }
   ```
   
   Dove `{{emails}}` è la variabile che contiene l'array di email dal nodo precedente.

   **Response Type:**
   ```
   JSON
   ```

### Esempio di Flow

1. **Nodo precedente** (es. Memory o Function) che produce i dati delle email
2. **Nodo HTTP Request** configurato come sopra
3. Il nodo HTTP invierà i dati al backend che li salverà
4. La dashboard si aggiornerà automaticamente ogni 5 secondi

### Schema JSON Richiesto

Il backend si aspetta questo schema:

```json
{
  "emails": [
    {
      "mittente": "string",
      "oggetto": "string",
      "riassunto": "string",
      "rischio": "alto" | "medio" | "basso"
    }
  ]
}
```

## 📊 Funzionalità Dashboard

- **Statistiche in tempo reale**: Totale email, conteggio per livello di rischio
- **Visualizzazione email**: Cards con tutte le informazioni
- **Aggiornamento automatico**: Polling ogni 5 secondi
- **Pulizia dati**: Bottone per eliminare tutte le email salvate

## 🔧 API Endpoints

### POST `/api/emails`
Riceve email da Flowise.

**Request Body:**
```json
{
  "emails": [
    {
      "mittente": "example@email.com",
      "oggetto": "Oggetto email",
      "riassunto": "Riassunto del contenuto",
      "rischio": "alto"
    }
  ]
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Ricevute 1 email",
  "count": 1
}
```

### GET `/api/emails`
Recupera tutte le email salvate.

**Response:**
```json
{
  "emails": [...],
  "count": 10
}
```

### DELETE `/api/emails`
Elimina tutte le email salvate.

**Response:**
```json
{
  "status": "success",
  "message": "Eliminate 10 email"
}
```

## 🛠️ Sviluppo

### Backend
- FastAPI per l'API
- Pydantic per la validazione
- Storage in memoria (per produzione, considera un database)

### Frontend
- React 18
- Vite per il build
- Axios per le chiamate API
- CSS moderno con gradient e animazioni

## 🚀 Deploy su Digital Ocean

### Deploy con Docker Compose (Consigliato)

Per il deploy con Docker Compose, consulta:
- **[DEPLOY_DOCKER.md](DEPLOY_DOCKER.md)** - Guida completa Docker Compose

**Quick Deploy:**
```bash
# Sul droplet
cd /opt/spam-dashboard
docker-compose up -d --build
```

### Deploy Tradizionale (Alternativa)

Per il deploy tradizionale senza Docker:
- **[DEPLOY_DIGITALOCEAN.md](DEPLOY_DIGITALOCEAN.md)** - Guida dettagliata passo-passo
- **[QUICK_DEPLOY.md](QUICK_DEPLOY.md)** - Riepilogo rapido

## 📝 Note

- Il backend attualmente salva i dati in memoria. Per produzione, considera l'uso di un database (PostgreSQL, MongoDB, etc.)
- Il CORS è configurato per permettere tutte le origini. In produzione, restringi a domini specifici
- Il polling del frontend è configurato a 5 secondi. Puoi modificarlo in `frontend/src/App.jsx`

