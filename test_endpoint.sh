#!/bin/bash

# Script di test per l'endpoint /api/emails

API_URL="http://localhost:8000/api/emails"

echo "🧪 Test endpoint Spam Dashboard"
echo "================================"
echo ""

# Test 1: Singola email
echo "📧 Test 1: Invio singola email..."
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "emails": [
      {
        "mittente": "phishing@example.com",
        "oggetto": "URGENTE: Verifica il tuo account",
        "riassunto": "Email sospetta che richiede credenziali con urgenza",
        "rischio": "alto"
      }
    ]
  }' | jq '.'

echo ""
echo ""

# Test 2: Multiple email
echo "📧 Test 2: Invio multiple email..."
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "emails": [
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
  }' | jq '.'

echo ""
echo ""

# Test 3: Recupero email
echo "📊 Test 3: Recupero tutte le email..."
curl -X GET "$API_URL" | jq '.'

echo ""
echo ""
echo "✅ Test completati!"

