#!/bin/bash

# Script di setup iniziale per Digital Ocean Droplet
# Esegui come root: sudo bash setup_server.sh

set -e

echo "🚀 Setup iniziale server Digital Ocean per Spam Dashboard"
echo "========================================================="

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Variabili
APP_USER="spamdashboard"
APP_DIR="/home/$APP_USER/spam-dashboard"

# 1. Aggiornamento sistema
echo -e "${YELLOW}📦 Aggiornamento sistema...${NC}"
apt update && apt upgrade -y

# 2. Installazione dipendenze base
echo -e "${YELLOW}📦 Installazione dipendenze...${NC}"
apt install -y python3 python3-pip python3-venv build-essential curl wget git

# 3. Installazione Node.js
echo -e "${YELLOW}📦 Installazione Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 4. Installazione Poetry
echo -e "${YELLOW}📦 Installazione Poetry...${NC}"
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 5. Installazione Nginx e Certbot
echo -e "${YELLOW}📦 Installazione Nginx e Certbot...${NC}"
apt install -y nginx certbot python3-certbot-nginx

# 6. Configurazione Firewall
echo -e "${YELLOW}🔥 Configurazione firewall...${NC}"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 8000/tcp
ufw --force enable

# 7. Creazione utente applicazione
echo -e "${YELLOW}👤 Creazione utente applicazione...${NC}"
if id "$APP_USER" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Utente $APP_USER già esistente${NC}"
else
    adduser --disabled-password --gecos "" $APP_USER
    usermod -aG sudo $APP_USER
    echo -e "${GREEN}✅ Utente $APP_USER creato${NC}"
fi

# 8. Creazione directory applicazione
echo -e "${YELLOW}📁 Creazione directory applicazione...${NC}"
mkdir -p $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

# 9. Creazione file systemd service
echo -e "${YELLOW}⚙️  Creazione systemd service...${NC}"
cat > /etc/systemd/system/spam-dashboard-api.service << 'EOF'
[Unit]
Description=Spam Dashboard API
After=network.target

[Service]
Type=simple
User=spamdashboard
WorkingDirectory=/home/spamdashboard/spam-dashboard
Environment="PATH=/home/spamdashboard/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/home/spamdashboard/.local/bin/poetry run uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# 10. Template configurazione Nginx
echo -e "${YELLOW}🌐 Creazione template Nginx...${NC}"
cat > /etc/nginx/sites-available/spam-dashboard << 'EOF'
# Backend API
server {
    listen 80;
    server_name _;  # Sostituisci con il tuo dominio

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Frontend
server {
    listen 80 default_server;
    server_name _;  # Sostituisci con il tuo dominio

    root /home/spamdashboard/spam-dashboard/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# 11. Abilita sito Nginx
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/spam-dashboard /etc/nginx/sites-enabled/
nginx -t

echo ""
echo -e "${GREEN}✅ Setup iniziale completato!${NC}"
echo ""
echo "📝 Prossimi passi:"
echo "1. Carica i file del progetto in: $APP_DIR"
echo "2. Come utente $APP_USER, esegui:"
echo "   cd $APP_DIR"
echo "   poetry install --no-dev"
echo "   cd frontend && npm install && npm run build"
echo "3. Aggiorna /etc/nginx/sites-available/spam-dashboard con il tuo dominio"
echo "4. Avvia i servizi:"
echo "   sudo systemctl enable spam-dashboard-api"
echo "   sudo systemctl start spam-dashboard-api"
echo "   sudo systemctl restart nginx"
echo "5. Se hai un dominio, configura SSL:"
echo "   sudo certbot --nginx -d yourdomain.com"
echo ""

