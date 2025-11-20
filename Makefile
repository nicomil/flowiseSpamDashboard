.PHONY: help build up down restart logs clean test

help: ## Mostra questo messaggio di aiuto
	@echo "Comandi disponibili:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Costruisce le immagini Docker
	docker-compose build

up: ## Avvia i container
	docker-compose up -d

down: ## Ferma i container
	docker-compose down

restart: ## Riavvia i container
	docker-compose restart

logs: ## Mostra i log dei container
	docker-compose logs -f

logs-backend: ## Mostra i log del backend
	docker-compose logs -f backend

logs-frontend: ## Mostra i log del frontend
	docker-compose logs -f frontend

clean: ## Rimuove container, volumi e immagini non utilizzate
	docker-compose down -v
	docker system prune -f

rebuild: ## Ricostruisce e riavvia i container
	docker-compose up -d --build

status: ## Mostra lo stato dei container
	docker-compose ps

test: ## Testa gli endpoint
	@echo "Test backend..."
	@curl -s http://localhost:8000/ | head -1
	@echo "\nTest frontend..."
	@curl -s http://localhost/ | head -1
	@echo "\nTest API..."
	@curl -s http://localhost/api/emails | head -1

shell-backend: ## Apre una shell nel container backend
	docker-compose exec backend bash

shell-frontend: ## Apre una shell nel container frontend
	docker-compose exec frontend sh

