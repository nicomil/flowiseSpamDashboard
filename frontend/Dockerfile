# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copia file di dipendenze
COPY frontend/package*.json ./

# Installa dipendenze
RUN npm ci

# Copia codice sorgente
COPY frontend/ ./

# Build applicazione
RUN npm run build

# Stage 2: Production con Nginx
FROM nginx:alpine

# Copia build da stage precedente
COPY --from=builder /app/dist /usr/share/nginx/html

# Copia configurazione Nginx personalizzata
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

