#!/bin/bash

# Script di deploy per Digital Ocean
# Esegui questo script sul server dopo aver fatto push delle modifiche

set -e  # Exit on error

echo "🚀 Inizio deploy Spam Dashboard..."

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory progetto
PROJECT_DIR="/home/spamdashboard/spam-dashboard"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Verifica che siamo nella directory corretta
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Directory progetto non trovata: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Backend
echo -e "${YELLOW}📦 Aggiornamento backend...${NC}"
cd "$BACKEND_DIR"
if [ -f "pyproject.toml" ]; then
    poetry install --no-dev
else
    echo "⚠️  pyproject.toml non trovato, skip backend update"
fi

# Frontend
echo -e "${YELLOW}📦 Build frontend...${NC}"
cd "$FRONTEND_DIR"
if [ -f "package.json" ]; then
    npm install
    npm run build
    echo -e "${GREEN}✅ Frontend buildato${NC}"
else
    echo "⚠️  package.json non trovato, skip frontend build"
fi

# Riavvia servizi
echo -e "${YELLOW}🔄 Riavvio servizi...${NC}"
sudo systemctl restart spam-dashboard-api
sudo systemctl reload nginx

# Verifica stato
echo -e "${YELLOW}🔍 Verifica stato servizi...${NC}"
if sudo systemctl is-active --quiet spam-dashboard-api; then
    echo -e "${GREEN}✅ Backend attivo${NC}"
else
    echo "❌ Backend non attivo! Controlla i log: sudo journalctl -u spam-dashboard-api -n 50"
    exit 1
fi

if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx attivo${NC}"
else
    echo "❌ Nginx non attivo!"
    exit 1
fi

echo -e "${GREEN}✅ Deploy completato con successo!${NC}"

