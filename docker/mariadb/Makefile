# Variables
IMAGE_NAME = mariadb_ssh:004
COMPOSE_GALERA = docker-compose-galera.yml
COMPOSE_REPLI = docker-compose-repli.yml

.PHONY: help build-image up-galera down-galera logs-galera up-repli down-repli logs-repli test-repli test-galera clean-data

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Image Management
build-image: ## Build the base mariadb_ssh image
	docker build -t $(IMAGE_NAME) .

## Galera Cluster
up-galera: ## Start Galera cluster
	docker compose -f $(COMPOSE_GALERA) up -d

down-galera: ## Stop Galera cluster
	docker compose -f $(COMPOSE_GALERA) down

logs-galera: ## Follow Galera cluster logs
	docker compose -f $(COMPOSE_GALERA) logs -f

## Replication Cluster
up-repli: ## Start Replication cluster
	docker compose -f $(COMPOSE_REPLI) up -d

down-repli: ## Stop Replication cluster
	docker compose -f $(COMPOSE_REPLI) down

logs-repli: ## Follow Replication cluster logs
	docker compose -f $(COMPOSE_REPLI) logs -f

test-repli: ## Run replication tests on the active cluster
	@chmod +x test_repli.sh
	./test_repli.sh

test-galera: ## Run Galera cluster tests on the active cluster
	@chmod +x test_galera.sh
	./test_galera.sh

## Utility
clean-data: ## Remove data and backup directories (CAUTION!)
	rm -rf gdatadir_* gbackups_* datadir_* backups_*
