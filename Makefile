COMPOSE_FILE=docker-compose.local.yml
COMPOSE=docker compose

.PHONY: up down logs rebuild clean ps

up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f

rebuild:
	$(COMPOSE) -f $(COMPOSE_FILE) build --no-cache

clean: down
	$(COMPOSE) -f $(COMPOSE_FILE) rm -f
	docker volume prune -f

ps:
	$(COMPOSE) -f $(COMPOSE_FILE) ps
