# Variables
IMAGE_NAME = mariadb_ssh:004
COMPOSE_GALERA = docker-compose-galera.yml
COMPOSE_REPLI = docker-compose-repli.yml

.PHONY: help build-image up-galera down-galera logs-galera up-repli down-repli logs-repli test-repli test-galera clean-data clean-galera clean-repli

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Image Management
build-image: ## Build the base mariadb_ssh image
	docker build -t $(IMAGE_NAME) .

install-client: ## Install MariaDB client on the host (Ubuntu/Debian)
	sudo apt-get update && sudo apt-get install -y mariadb-client

## Galera Cluster
up-galera: build-image down-repli ## Start Galera cluster
	docker compose -f $(COMPOSE_GALERA) up -d

bootstrap-galera: build-image down-repli ## Bootstrap a NEW Galera cluster
	@echo ">> 🚀 Bootstrapping Node 1..."
	MARIADB_GALERA_BOOTSTRAP=1 docker compose -f $(COMPOSE_GALERA) up -d galera_01
	@echo ">> ⏳ Waiting for Node 1 to be ready..."
	@sleep 20
	@echo ">> 🚀 Starting rest of the cluster..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate

down-galera: ## Stop Galera cluster
	docker compose -f $(COMPOSE_GALERA) down

logs-galera: ## Follow Galera cluster logs
	docker compose -f $(COMPOSE_GALERA) logs -f

## Replication Cluster
up-repli: build-image down-galera ## Start Replication cluster
	docker compose -f $(COMPOSE_REPLI) up -d

down-repli: ## Stop Replication cluster
	docker compose -f $(COMPOSE_REPLI) down

logs-repli: ## Follow Replication cluster logs
	docker compose -f $(COMPOSE_REPLI) logs -f

test-repli: ## Run replication tests on the active cluster
	bash ./test_repli.sh

setup-repli: ## Configure Master/Slave relationship
	bash ./setup_repli.sh

test-galera: ## Run advanced Galera cluster tests (Replication, DDL, Conflicts, Auto-inc)
	bash ./test_galera.sh

test-perf-repli: ## Run performance tests on Replication (Usage: make test-perf-repli PROFILE=light ACTION=run)
	bash ./test_perf_repli.sh $(PROFILE) $(ACTION)

test-perf-galera: ## Run performance tests on Galera (Usage: make test-perf-galera PROFILE=light ACTION=run)
	bash ./test_perf_galera.sh $(PROFILE) $(ACTION)

test-perf: ## [DEPRECATED] Use test-perf-galera or test-perf-repli
	@echo "❌ 'make test-perf' is deprecated. Please use 'make test-perf-galera' or 'make test-perf-repli'"

## Backup & Restore (Logical)
backup-galera: ## Backup Galera cluster (Usage: make backup-galera [DB=name])
	bash ./backup_logical.sh galera $(DB)

restore-galera: ## Restore Galera cluster (Usage: make restore-galera FILE=filename.sql.gz)
	bash ./restore_logical.sh galera $(FILE)

backup-repli: ## Backup Replication cluster (Usage: make backup-repli [DB=name])
	bash ./backup_logical.sh repli $(DB)

restore-repli: ## Restore Replication cluster (Usage: make restore-repli FILE=filename.sql.gz)
	bash ./restore_logical.sh repli $(FILE)

## Backup & Restore (Physical - MariaBackup)
backup-phys-galera: ## Physical backup Galera (Usage: make backup-phys-galera)
	bash ./backup_physical.sh galera

restore-phys-galera: ## Physical restore Galera (Usage: make restore-phys-galera FILE=filename.tar.gz)
	bash ./restore_physical.sh galera $(FILE)

backup-phys-repli: ## Physical backup Replication (Usage: make backup-phys-repli)
	./backup_physical.sh repli

restore-phys-repli: ## Physical restore Replication (Usage: make restore-phys-repli FILE=filename.tar.gz)
	./restore_physical.sh repli $(FILE)

## Utility
clean-galera: down-galera ## Stop Galera and remove all data/backups (CAUTION!)
	rm -rf gdatadir_* gbackups_*

clean-repli: down-repli ## Stop Replication and remove all data/backups (CAUTION!)
	rm -rf datadir_* backups_*

gen-profiles: ## Generate shell profile files with aliases
	@chmod +x gen_profiles.sh
	./gen_profiles.sh

clean-data: clean-galera clean-repli ## Remove ALL data and backup directories (CAUTION!)
