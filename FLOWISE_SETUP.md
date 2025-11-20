# 📋 Guida Completa Configurazione Flowise

## Endpoint da Configurare

**URL:** `http://localhost:8000/api/emails`  
**Method:** `POST`  
**Content-Type:** `application/json`

## Configurazione Dettagliata del Nodo HTTP Request

### 1. URL
```
http://localhost:8000/api/emails
```
> **Nota:** Se il backend è su un altro server, sostituisci `localhost:8000` con l'URL completo del tuo server (es. `http://192.168.1.100:8000/api/emails`)

### 2. Method
Seleziona: **POST**

### 3. Headers
Aggiungi questo header:
```
Content-Type: application/json
```

### 4. Body Type
Seleziona: **JSON**

### 5. Body (JSON)

#### Opzione A: Se hai già un array di email dal nodo precedente
Se il nodo precedente produce già un array di email nel formato corretto, usa:
```json
{
  "emails": {{emails}}
}
```
Dove `{{emails}}` è la variabile che contiene l'array dal nodo precedente.

#### Opzione B: Se hai una singola email
Se processi una email alla volta:
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

#### Opzione C: Se hai più email da aggregare
Se hai più email da inviare insieme:
```json
{
  "emails": [
    {
      "mittente": "{{email1.mittente}}",
      "oggetto": "{{email1.oggetto}}",
      "riassunto": "{{email1.riassunto}}",
      "rischio": "{{email1.rischio}}"
    },
    {
      "mittente": "{{email2.mittente}}",
      "oggetto": "{{email2.oggetto}}",
      "riassunto": "{{email2.riassunto}}",
      "rischio": "{{email2.rischio}}"
    }
  ]
}
```

### 6. Response Type
Seleziona: **JSON**

Il backend risponderà con:
```json
{
  "status": "success",
  "message": "Ricevute N email",
  "count": N
}
```

## Esempio di Flow Completo

```
[Input] → [Agent/ChatFlow] → [Memory/Function] → [HTTP Request] → [Output]
```

1. **Input Node**: Riceve l'email da analizzare
2. **Agent/ChatFlow Node**: Analizza l'email e estrae informazioni
3. **Memory/Function Node**: Struttura i dati nel formato richiesto
4. **HTTP Request Node**: Invia i dati alla dashboard
5. **Output Node**: Mostra la risposta

## Esempio di Dati di Test

Per testare l'endpoint, puoi usare questo JSON:

```json
{
  "emails": [
    {
      "mittente": "phishing@example.com",
      "oggetto": "URGENTE: Verifica il tuo account",
      "riassunto": "Email sospetta che richiede credenziali con urgenza",
      "rischio": "alto"
    },
    {
      "mittente": "newsletter@company.com",
      "oggetto": "Le nostre offerte speciali",
      "riassunto": "Newsletter promozionale standard",
      "rischio": "basso"
    },
    {
      "mittente": "unknown@sender.net",
      "oggetto": "Richiesta di contatto",
      "riassunto": "Email da mittente sconosciuto con link esterno",
      "rischio": "medio"
    }
  ]
}
```

## Troubleshooting

### Errore: "Connection refused"
- Verifica che il backend sia in esecuzione su `http://localhost:8000`
- Controlla che non ci siano firewall che bloccano la connessione
- Se Flowise è su un altro server, usa l'IP del server invece di `localhost`

### Errore: "Validation error"
- Verifica che il JSON rispetti lo schema richiesto
- Controlla che tutti i campi obbligatori siano presenti: `mittente`, `oggetto`, `riassunto`, `rischio`
- Verifica che `rischio` sia uno di: `"alto"`, `"medio"`, `"basso"` (case-sensitive)

### Le email non appaiono nella dashboard
- Verifica che l'endpoint risponda con status 200
- Controlla la console del browser per errori
- Verifica che il frontend stia facendo polling all'endpoint corretto

## Test Manuale dell'Endpoint

Puoi testare l'endpoint manualmente con curl:

```bash
curl -X POST http://localhost:8000/api/emails \
  -H "Content-Type: application/json" \
  -d '{
    "emails": [
      {
        "mittente": "test@example.com",
        "oggetto": "Test Email",
        "riassunto": "Questa è una email di test",
        "rischio": "medio"
      }
    ]
  }'
```

Dovresti ricevere una risposta:
```json
{
  "status": "success",
  "message": "Ricevute 1 email",
  "count": 1
}
```

