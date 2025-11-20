# 🐳 Docker Quick Start

Guida rapida per avviare la Spam Dashboard con Docker Compose.

## 🚀 Avvio Rapido

```bash
# 1. Clona/carica il progetto
cd /opt/spam-dashboard  # o la tua directory preferita

# 2. Avvia tutto
docker-compose up -d --build

# 3. Verifica che funzioni
curl http://localhost/api/emails
```

## 📋 Comandi Essenziali

```bash
# Avvia
docker-compose up -d

# Ferma
docker-compose down

# Log
docker-compose logs -f

# Riavvia
docker-compose restart

# Ricostruisci
docker-compose up -d --build
```

## 🔧 Con Makefile

```bash
make help      # Mostra tutti i comandi
make up        # Avvia
make down      # Ferma
make logs      # Log
make rebuild   # Ricostruisci
make test      # Test endpoint
```

## 🌐 Accesso

- **Frontend:** http://localhost
- **Backend API:** http://localhost:8000
- **API via Frontend:** http://localhost/api/emails

## 📡 Configurazione Flowise

Endpoint da usare nel nodo HTTP Request:
```
http://your-server-ip/api/emails
```

Oppure se hai un dominio:
```
https://yourdomain.com/api/emails
```

## 🐛 Troubleshooting

### Container non si avvia
```bash
docker-compose logs backend
docker-compose logs frontend
```

### Porta già in uso
```bash
# Verifica cosa usa la porta
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8000

# Cambia porte in docker-compose.yml se necessario
```

### Ricostruisci da zero
```bash
docker-compose down -v
docker-compose up -d --build
```

## 📚 Documentazione Completa

Per dettagli completi sul deploy, vedi [DEPLOY_DOCKER.md](DEPLOY_DOCKER.md)

