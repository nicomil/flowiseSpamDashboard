# 🔧 Troubleshooting

## Porta 80 già in uso

Se ricevi l'errore `address already in use` per la porta 80:

### 1. Identifica il processo

```bash
# Su Linux
sudo netstat -tlnp | grep :80
# oppure
sudo lsof -i :80
# oppure
sudo ss -tlnp | grep :80
```

### 2. Ferma il processo

```bash
# Se è Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx  # Per evitare che si riavvii automaticamente

# Se è Apache
sudo systemctl stop apache2
sudo systemctl disable apache2

# Se è un altro processo, usa il PID trovato
sudo kill -9 <PID>
```

### 3. Alternativa: Cambia porta nel docker-compose.yml

Se vuoi mantenere Nginx/Apache attivo, cambia la porta del frontend:

```yaml
frontend:
  ports:
    - "8080:80"  # Usa porta 8080 invece di 80
```

Poi accedi a `http://your-server:8080`

### 4. Verifica che la porta sia libera

```bash
sudo netstat -tlnp | grep :80
# Non dovrebbe restituire nulla
```

## Altri problemi comuni

### Container non si avvia

```bash
# Verifica log
docker compose logs backend
docker compose logs frontend

# Verifica configurazione
docker compose config
```

### Porta 8000 già in uso

```bash
# Trova il processo
sudo lsof -i :8000

# Ferma o cambia porta in docker-compose.yml
```

### Problemi di permessi

```bash
# Verifica permessi
ls -la /var/run/docker.sock

# Se necessario
sudo chmod 666 /var/run/docker.sock
```

