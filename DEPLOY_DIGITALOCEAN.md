# 🚀 Guida Deploy su Digital Ocean

Guida completa per deployare la Spam Dashboard su un droplet Digital Ocean.

## 📋 Prerequisiti

- Droplet Digital Ocean attivo
- Accesso SSH al droplet
- Dominio configurato (opzionale ma consigliato)
- Conoscenza base di Linux

## 🔧 Step 1: Setup Iniziale del Droplet

### 1.1 Connessione SSH

```bash
ssh root@your-droplet-ip
```

### 1.2 Aggiornamento Sistema

```bash
apt update && apt upgrade -y
```

### 1.3 Installazione Dipendenze Base

```bash
# Installazione Python 3.10+ e pip
apt install -y python3 python3-pip python3-venv build-essential

# Installazione Node.js 18+ (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Installazione Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Aggiungi Poetry al PATH (per questa sessione)
export PATH="$HOME/.local/bin:$PATH"

# Aggiungi al .bashrc per renderlo permanente
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Installazione Nginx
apt install -y nginx

# Installazione Certbot per SSL
apt install -y certbot python3-certbot-nginx

# Installazione Git (se non presente)
apt install -y git
```

### 1.4 Configurazione Firewall

```bash
# Abilita UFW
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 8000/tcp  # Porta backend (temporanea, poi useremo Nginx)
ufw enable
ufw status
```

## 📦 Step 2: Setup Applicazione

### 2.1 Creazione Utente Non-Root (Sicurezza)

```bash
# Crea utente
adduser spamdashboard
usermod -aG sudo spamdashboard

# Passa all'utente
su - spamdashboard
```

### 2.2 Clonazione Repository

```bash
# Se hai un repository Git
git clone <your-repo-url> /home/spamdashboard/spam-dashboard
cd /home/spamdashboard/spam-dashboard

# Oppure carica i file via SCP da locale:
# scp -r /path/to/spamDashboardFlowise/* spamdashboard@your-droplet-ip:/home/spamdashboard/spam-dashboard/
```

### 2.3 Setup Backend

```bash
cd /home/spamdashboard/spam-dashboard

# Installa dipendenze con Poetry
poetry install --no-dev

# Crea file .env
cat > backend/.env << EOF
ENVIRONMENT=production
API_PORT=8000
FRONTEND_URL=https://yourdomain.com
EOF
```

### 2.4 Setup Frontend

```bash
cd /home/spamdashboard/spam-dashboard/frontend

# Installa dipendenze
npm install

# Build produzione
npm run build

# Il build sarà in frontend/dist/
```

## 🔄 Step 3: Configurazione Systemd (Backend Service)

### 3.1 Crea Service File

```bash
sudo nano /etc/systemd/system/spam-dashboard-api.service
```

Inserisci questo contenuto:

```ini
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
```

### 3.2 Abilita e Avvia Service

```bash
# Ricarica systemd
sudo systemctl daemon-reload

# Abilita servizio (avvio automatico)
sudo systemctl enable spam-dashboard-api

# Avvia servizio
sudo systemctl start spam-dashboard-api

# Verifica stato
sudo systemctl status spam-dashboard-api

# Visualizza log
sudo journalctl -u spam-dashboard-api -f
```

## 🌐 Step 4: Configurazione Nginx

### 4.1 Configurazione Reverse Proxy

```bash
sudo nano /etc/nginx/sites-available/spam-dashboard
```

Inserisci questa configurazione:

```nginx
# Backend API
server {
    listen 80;
    server_name api.yourdomain.com;  # Sostituisci con il tuo dominio o IP

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

    # Health check
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Frontend
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;  # Sostituisci con il tuo dominio

    root /home/spamdashboard/spam-dashboard/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
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

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 4.2 Abilita Sito e Test

```bash
# Crea symlink
sudo ln -s /etc/nginx/sites-available/spam-dashboard /etc/nginx/sites-enabled/

# Rimuovi default (opzionale)
sudo rm /etc/nginx/sites-enabled/default

# Test configurazione
sudo nginx -t

# Riavvia Nginx
sudo systemctl restart nginx
```

### 4.3 SSL con Let's Encrypt (Se hai un dominio)

```bash
# Ottieni certificato SSL
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com -d api.yourdomain.com

# Test rinnovo automatico
sudo certbot renew --dry-run
```

## 🔒 Step 5: Configurazione Sicurezza

### 5.1 Aggiorna Firewall

```bash
# Rimuovi accesso diretto alla porta 8000 (ora usiamo Nginx)
sudo ufw delete allow 8000/tcp

# Verifica
sudo ufw status
```

### 5.2 Configura CORS nel Backend (se necessario)

Se hai un dominio specifico, aggiorna `backend/main.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com", "https://www.yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🔄 Step 6: Aggiornamento Flowise

### 6.1 Nuovo Endpoint

Aggiorna il nodo HTTP Request in Flowise con il nuovo URL:

**Se hai un dominio:**
```
https://api.yourdomain.com/api/emails
```

**Se usi solo IP:**
```
http://your-droplet-ip/api/emails
```

### 6.2 Headers (se necessario)

Se hai configurato autenticazione, aggiungi gli header necessari nel nodo HTTP di Flowise.

## 📝 Step 7: Script di Deploy

Crea uno script per semplificare i futuri deploy:

```bash
nano /home/spamdashboard/deploy.sh
```

```bash
#!/bin/bash

cd /home/spamdashboard/spam-dashboard

# Pull ultime modifiche (se usi Git)
# git pull origin main

# Backend
cd /home/spamdashboard/spam-dashboard
poetry install --no-dev
sudo systemctl restart spam-dashboard-api

# Frontend
cd /home/spamdashboard/spam-dashboard/frontend
npm install
npm run build

# Riavvia Nginx
sudo systemctl reload nginx

echo "✅ Deploy completato!"
```

```bash
chmod +x /home/spamdashboard/deploy.sh
```

## 🔍 Step 8: Monitoraggio e Log

### 8.1 Log Backend

```bash
# Log in tempo reale
sudo journalctl -u spam-dashboard-api -f

# Ultimi 100 log
sudo journalctl -u spam-dashboard-api -n 100

# Log con timestamp
sudo journalctl -u spam-dashboard-api --since "1 hour ago"
```

### 8.2 Log Nginx

```bash
# Access log
sudo tail -f /var/log/nginx/access.log

# Error log
sudo tail -f /var/log/nginx/error.log
```

### 8.3 Health Check

```bash
# Test endpoint
curl http://localhost:8000/

# Test API
curl http://localhost:8000/api/emails
```

## 🛠️ Comandi Utili

### Riavviare Servizi

```bash
# Backend
sudo systemctl restart spam-dashboard-api

# Nginx
sudo systemctl restart nginx

# Entrambi
sudo systemctl restart spam-dashboard-api nginx
```

### Verificare Stato

```bash
# Stato backend
sudo systemctl status spam-dashboard-api

# Stato Nginx
sudo systemctl status nginx

# Porte in ascolto
sudo netstat -tlnp | grep -E ':(80|443|8000)'
```

### Aggiornare Applicazione

```bash
# Esegui script deploy
/home/spamdashboard/deploy.sh
```

## 🐛 Troubleshooting

### Backend non si avvia

```bash
# Controlla log
sudo journalctl -u spam-dashboard-api -n 50

# Verifica permessi
ls -la /home/spamdashboard/spam-dashboard

# Test manuale
cd /home/spamdashboard/spam-dashboard
poetry run uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### Nginx error 502

```bash
# Verifica che backend sia in ascolto
curl http://localhost:8000/

# Controlla configurazione Nginx
sudo nginx -t

# Verifica log errori
sudo tail -f /var/log/nginx/error.log
```

### Frontend non carica

```bash
# Verifica che dist/ esista
ls -la /home/spamdashboard/spam-dashboard/frontend/dist

# Verifica permessi
sudo chown -R spamdashboard:spamdashboard /home/spamdashboard/spam-dashboard/frontend/dist

# Verifica configurazione Nginx
sudo nginx -t
```

## 📊 Checklist Deploy

- [ ] Sistema aggiornato
- [ ] Python 3.10+ installato
- [ ] Node.js 18+ installato
- [ ] Poetry installato
- [ ] Nginx installato e configurato
- [ ] Firewall configurato
- [ ] Backend service creato e attivo
- [ ] Frontend buildato
- [ ] Nginx configurato come reverse proxy
- [ ] SSL configurato (se dominio disponibile)
- [ ] Endpoint Flowise aggiornato
- [ ] Test endpoint funzionante
- [ ] Log monitorati

## 🔐 Sicurezza Aggiuntiva (Opzionale)

### Fail2Ban

```bash
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### Auto-updates

```bash
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

## 📞 Supporto

In caso di problemi:
1. Controlla i log: `sudo journalctl -u spam-dashboard-api -f`
2. Verifica configurazione Nginx: `sudo nginx -t`
3. Test endpoint: `curl http://localhost:8000/api/emails`

