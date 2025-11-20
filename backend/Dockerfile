FROM python:3.11-slim

WORKDIR /app

# Installa dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installa Poetry
RUN pip install --no-cache-dir poetry==1.7.1

# Configura Poetry per non creare virtualenv (usa il sistema)
RUN poetry config virtualenvs.create false

# Copia file di dipendenze (dalla root del progetto)
COPY pyproject.toml poetry.lock* ./

# Installa dipendenze
RUN poetry install --no-dev --no-interaction --no-ansi

# Copia codice applicazione
COPY backend/ ./backend/

# Esponi porta
EXPOSE 8000

# Health check (usa curl invece di requests)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando di avvio
CMD ["poetry", "run", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]

