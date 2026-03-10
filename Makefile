SHELL := /bin/bash

.PHONY: help up start down stop rebuild logs ps shell compile test format

help:
	@echo "Available targets:"
	@echo "  make up       - start Sparkdeck, reusing existing Postgres when available"
	@echo "  make down     - stop Sparkdeck containers"
	@echo "  make rebuild  - rebuild and start from scratch"
	@echo "  make logs     - tail Docker Compose logs"
	@echo "  make ps       - show running Docker Compose services"
	@echo "  make shell    - open a shell in the web container"
	@echo "  make compile  - run mix compile in the web container"
	@echo "  make test     - run mix test in the web container"
	@echo "  make format   - run mix format in the web container"

up:
	@./bin/dev-up

start: up

down:
	@./bin/dev-down

stop: down

rebuild:
	@docker compose --profile local-db down -v
	@./bin/dev-up

logs:
	@docker compose logs -f

ps:
	@docker compose ps

shell:
	@docker compose exec web /bin/sh

compile:
	@docker compose exec web mix compile

test:
	@docker compose exec web mix test

format:
	@docker compose exec web mix format
