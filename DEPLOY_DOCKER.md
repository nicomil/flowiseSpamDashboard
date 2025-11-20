# 🐳 Deploy con Docker Compose

Guida completa per deployare la Spam Dashboard usando Docker Compose su Digital Ocean.

## 📋 Prerequisiti

- Droplet Digital Ocean attivo
- Docker e Docker Compose installati
- Accesso SSH al droplet
- Dominio configurato (opzionale ma consigliato)

## 🚀 Quick Start

### 1. Connettiti al Droplet

```bash
ssh root@your-droplet-ip
```

### 2. Clona/Carica il Progetto

```bash
# Opzione A: Se hai un repository Git
git clone <your-repo-url> /opt/spam-dashboard
cd /opt/spam-dashboard

# Opzione B: Carica i file via SCP (da locale)
# scp -r /path/to/spamDashboardFlowise/* root@your-droplet-ip:/opt/spam-dashboard/
```

### 3. Avvia con Docker Compose

```bash
cd /opt/spam-dashboard

# Build e avvio
docker-compose up -d --build

# Verifica che i container siano attivi
docker-compose ps

# Visualizza log
docker-compose logs -f
```

### 4. Verifica Funzionamento

```bash
# Test backend
curl http://localhost:8000/

# Test frontend
curl http://localhost/

# Test API
curl http://localhost/api/emails
```

## 🔧 Configurazione Avanzata

### Variabili d'Ambiente

Crea un file `.env` nella root del progetto:

```bash
nano /opt/spam-dashboard/.env
```

```env
ENVIRONMENT=production
API_PORT=8000
FRONTEND_URL=https://yourdomain.com
```

Poi aggiorna `docker-compose.yml` per usare il file `.env`:

```yaml
services:
  backend:
    env_file:
      - .env
```

### Configurazione Nginx per SSL (Produzione)

Se hai un dominio e vuoi usare SSL, puoi usare un reverse proxy Nginx esterno o configurare Let's Encrypt.

#### Opzione 1: Nginx Reverse Proxy (Consigliato)

1. Installa Nginx sul droplet:

```bash
apt update
apt install -y nginx certbot python3-certbot-nginx
```

2. Crea configurazione Nginx:

```bash
nano /etc/nginx/sites-available/spam-dashboard
```

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Frontend
    location / {
        proxy_pass http://localhost:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API (se vuoi esporre direttamente)
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

3. Abilita sito e ottieni certificato SSL:

```bash
ln -s /etc/nginx/sites-available/spam-dashboard /etc/nginx/sites-enabled/
nginx -t
certbot --nginx -d yourdomain.com -d www.yourdomain.com
systemctl restart nginx
```

4. Aggiorna `docker-compose.yml` per non esporre direttamente le porte:

```yaml
services:
  backend:
    # Rimuovi ports, usa solo expose
    expose:
      - "8000"
  
  frontend:
    # Cambia porta da 80 a 8080 (Nginx userà 80)
    ports:
      - "8080:80"
```

Poi aggiorna il proxy_pass in Nginx a `http://localhost:8080`.

#### Opzione 2: Traefik (Avanzato)

Per una soluzione più moderna, puoi usare Traefik come reverse proxy automatico.

### Firewall

```bash
# Configura UFW
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## 📝 Comandi Utili

### Gestione Container

```bash
# Avvia servizi
docker-compose up -d

# Ferma servizi
docker-compose down

# Riavvia servizi
docker-compose restart

# Ricostruisci e avvia
docker-compose up -d --build

# Visualizza log
docker-compose logs -f
docker-compose logs -f backend
docker-compose logs -f frontend

# Entra nel container
docker-compose exec backend bash
docker-compose exec frontend sh
```

### Aggiornamento

```bash
cd /opt/spam-dashboard

# Pull ultime modifiche (se usi Git)
git pull origin main

# Ricostruisci e riavvia
docker-compose up -d --build

# Rimuovi immagini vecchie
docker image prune -f
```

### Backup e Restore

```bash
# Backup (se aggiungi un database in futuro)
docker-compose exec backend poetry run python backup.py

# Restore
docker-compose exec backend poetry run python restore.py
```

## 🔍 Monitoraggio

### Health Checks

I container hanno health checks configurati. Verifica lo stato:

```bash
docker-compose ps
```

### Log

```bash
# Log in tempo reale
docker-compose logs -f

# Ultimi 100 log del backend
docker-compose logs --tail=100 backend

# Log con timestamp
docker-compose logs -t
```

### Risorse

```bash
# Utilizzo risorse
docker stats

# Spazio disco
docker system df
```

## 🛠️ Troubleshooting

### Container non si avvia

```bash
# Verifica log
docker-compose logs backend
docker-compose logs frontend

# Verifica configurazione
docker-compose config

# Test build manuale
docker-compose build --no-cache
```

### Porta già in uso

```bash
# Verifica cosa usa la porta
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8000

# Cambia porte in docker-compose.yml se necessario
```

### Problemi di rete

```bash
# Verifica network
docker network ls
docker network inspect spam-dashboard-flowise_spam-dashboard-network

# Test connettività tra container
docker-compose exec backend ping frontend
```

### Permessi

```bash
# Se hai problemi di permessi
sudo chown -R $USER:$USER /opt/spam-dashboard
```

## 🔄 Deploy Automatico con Script

Crea uno script di deploy:

```bash
nano /opt/spam-dashboard/deploy-docker.sh
```

```bash
#!/bin/bash
set -e

cd /opt/spam-dashboard

echo "🔄 Pull ultime modifiche..."
git pull origin main

echo "🏗️  Build e avvio container..."
docker-compose up -d --build

echo "🧹 Pulizia immagini vecchie..."
docker image prune -f

echo "✅ Deploy completato!"
docker-compose ps
```

```bash
chmod +x /opt/spam-dashboard/deploy-docker.sh
```

## 📊 Configurazione Flowise

Dopo il deploy, aggiorna il nodo HTTP Request in Flowise:

**URL:**
```
http://your-droplet-ip/api/emails
# oppure se hai dominio
https://yourdomain.com/api/emails
```

**Configurazione rimane la stessa:**
- Method: `POST`
- Headers: `Content-Type: application/json`
- Body Type: `JSON`
- Body: vedi `FLOWISE_SETUP.md`

## 🔐 Sicurezza

### Best Practices

1. **Non esporre porte direttamente** - Usa Nginx come reverse proxy
2. **Usa SSL/TLS** - Configura Let's Encrypt
3. **Aggiorna regolarmente** - `docker-compose pull` e rebuild
4. **Limita risorse** - Aggiungi limits in docker-compose.yml:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

5. **Backup regolari** - Se aggiungi un database

## 📝 Checklist Deploy

- [ ] Docker e Docker Compose installati
- [ ] Progetto caricato sul server
- [ ] File `.env` configurato (se necessario)
- [ ] Container buildati e avviati
- [ ] Health checks passati
- [ ] Firewall configurato
- [ ] Nginx configurato (se usato)
- [ ] SSL configurato (se dominio disponibile)
- [ ] Endpoint Flowise aggiornato
- [ ] Test endpoint funzionante
- [ ] Log monitorati

## 🚀 Performance

Per ottimizzare le performance:

1. **Build cache** - Docker usa cache automaticamente
2. **Multi-stage builds** - Già implementato per frontend
3. **Health checks** - Già configurati
4. **Resource limits** - Aggiungi se necessario

## 📞 Supporto

In caso di problemi:
1. Controlla log: `docker-compose logs -f`
2. Verifica stato: `docker-compose ps`
3. Test connettività: `curl http://localhost/api/emails`

