# ⚡ Quick Deploy - Riepilogo Rapido

## Setup Iniziale (Una volta sola)

```bash
# 1. Connettiti al droplet
ssh root@your-droplet-ip

# 2. Setup base
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv build-essential
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
apt install -y nginx certbot python3-certbot-nginx git

# 3. Crea utente
adduser spamdashboard
usermod -aG sudo spamdashboard
su - spamdashboard

# 4. Carica progetto (da locale)
# scp -r /path/to/spamDashboardFlowise/* spamdashboard@your-droplet-ip:/home/spamdashboard/spam-dashboard/

# 5. Setup backend
cd /home/spamdashboard/spam-dashboard
poetry install --no-dev

# 6. Setup frontend
cd frontend
npm install
npm run build

# 7. Crea service systemd
sudo nano /etc/systemd/system/spam-dashboard-api.service
# (copia contenuto da DEPLOY_DIGITALOCEAN.md)

# 8. Configura Nginx
sudo nano /etc/nginx/sites-available/spam-dashboard
# (copia contenuto da DEPLOY_DIGITALOCEAN.md)

# 9. Abilita e avvia
sudo systemctl daemon-reload
sudo systemctl enable spam-dashboard-api
sudo systemctl start spam-dashboard-api
sudo ln -s /etc/nginx/sites-available/spam-dashboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# 10. SSL (se hai dominio)
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## Deploy Futuri

```bash
# Sul server
cd /home/spamdashboard/spam-dashboard
./deploy.sh
```

## Endpoint Flowise

```
https://api.yourdomain.com/api/emails
# oppure
http://your-droplet-ip/api/emails
```

## Comandi Utili

```bash
# Log backend
sudo journalctl -u spam-dashboard-api -f

# Riavvia backend
sudo systemctl restart spam-dashboard-api

# Riavvia Nginx
sudo systemctl restart nginx

# Test endpoint
curl http://localhost:8000/api/emails
```

