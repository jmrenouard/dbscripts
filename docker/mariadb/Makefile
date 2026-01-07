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
up-galera: build-image gen-ssl down-repli ## Start Galera cluster
	@echo ">> 🚀 Starting Node 1 (Primary)..."
	MARIADB_GALERA_BOOTSTRAP=1 docker compose -f $(COMPOSE_GALERA) up -d --no-recreate galera_01
	@echo ">> ⏳ Waiting for Node 1 to start..."
	@until docker exec mariadb-galera_01-1 mariadb -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 1; done
	@echo "✅ Node 1 is Synced."
	@echo ">> 🚀 Joining Node 2..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate galera_02
	@echo ">> ⏳ Waiting for Node 2 to join..."
	@until mariadb -h 127.0.0.1 -P 3512 -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 2; done
	@echo "✅ Node 2 is Synced."
	@echo ">> 🚀 Joining Node 3..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate galera_03
	@echo ">> ⏳ Waiting for Node 3 to join..."
	@until mariadb -h 127.0.0.1 -P 3513 -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 2; done
	@echo "✅ Node 3 is Synced."
	@echo ">> 🚀 Starting Load Balancer..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate haproxy_galera
	@echo "✅ Cluster is fully SEQUENTIALLY BOOTSTRAPPED and ready."

bootstrap-galera: build-image gen-ssl down-repli ## Bootstrap a NEW Galera cluster (Sequential)
	@echo ">> 🚀 Bootstrapping Node 1 (Primary)..."
	MARIADB_GALERA_BOOTSTRAP=1 docker compose -f $(COMPOSE_GALERA) up -d galera_01
	@echo ">> ⏳ Waiting for Node 1 to bootstrap..."
	@until docker exec mariadb-galera_01-1 mariadb -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 1; done
	@echo "✅ Node 1 is Synced."
	@echo ">> 🚀 Joining Node 2..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate galera_02
	@echo ">> ⏳ Waiting for Node 2 to join..."
	@until mariadb -h 127.0.0.1 -P 3512 -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 2; done
	@echo "✅ Node 2 is Synced."
	@echo ">> 🚀 Joining Node 3..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate galera_03
	@echo ">> ⏳ Waiting for Node 3 to join..."
	@until mariadb -h 127.0.0.1 -P 3513 -u root -prootpass -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" 2>/dev/null | grep -q "Synced"; do sleep 2; done
	@echo "✅ Node 3 is Synced."
	@echo ">> 🚀 Starting Load Balancer..."
	docker compose -f $(COMPOSE_GALERA) up -d --no-recreate haproxy_galera
	@echo "✅ Cluster is fully SEQUENTIALLY BOOTSTRAPPED and ready."

down-galera: ## Stop Galera cluster
	docker compose -f $(COMPOSE_GALERA) down

logs-galera: ## Follow Galera cluster logs
	docker compose -f $(COMPOSE_GALERA) logs -f

## Replication Cluster
up-repli: build-image gen-ssl down-galera ## Start Replication cluster
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

test-lb-galera: ## Run HAProxy load balancing test for Galera
	bash ./test_lb_galera.sh

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

## Full Cycle Targets (CI/CD style)
clean-reports:
	rm -rf reports/*.md reports/*.html

full-repli: clean-repli clean-ssl clean-reports up-repli setup-repli test-repli ## Full cycle for Replication: Clean, Start, Setup, and Test

full-galera: clean-galera clean-ssl clean-reports bootstrap-galera down-galera up-galera test-galera ## Full cycle for Galera: Clean, Start (Sequential), and Test

## Utility
clean-galera: down-galera ## Stop Galera and remove all data/backups (CAUTION!)
	rm -rf gdatadir_* gbackups_*

clean-repli: down-repli ## Stop Replication and remove all data/backups (CAUTION!)
	rm -rf datadir_* backups_*

gen-profiles: ## Generate shell profile files with aliases
	bash ./gen_profiles.sh

gen-ssl: ## Generate SSL certificates for MariaDB
	bash ./gen_ssl.sh

clean-ssl: ## Remove SSL certificates (REVERSIBLE)
	rm -rf ssl/

renew-ssl: ## Force SSL certificate regeneration and reload on active nodes
	@echo ">> 🔄 Regenerating SSL certificates..."
	rm -rf ssl/
	bash ./gen_ssl.sh
	@echo ">> 🚀 Reloading SSL on Galera nodes..."
	@docker exec mariadb-galera_01-1 mariadb -u root -prootpass -e "FLUSH SSL;" && echo "✅ Node 1 reloaded"
	@docker exec mariadb-galera_02-1 mariadb -u root -prootpass -e "FLUSH SSL;" && echo "✅ Node 2 reloaded"
	@docker exec mariadb-galera_03-1 mariadb -u root -prootpass -e "FLUSH SSL;" && echo "✅ Node 3 reloaded"
	@echo "✨ Zero-downtime SSL rotation completed."

clean-data: clean-galera clean-repli clean-ssl ## Remove ALL data, backup, and SSL directories (CAUTION!)

## Logs & Troubleshooting
logs-error-galera: ## Read last 100 lines of error logs for Galera (Usage: make logs-error-galera [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "galera_02";; 3) echo "galera_03";; *) echo "galera_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "galera02";; 3) echo "galera03";; *) echo "galera01";; esac); \
	docker compose -f $(COMPOSE_GALERA) exec $$SERVICE tail -n 100 /var/lib/mysql/$$HOST.err

follow-error-galera: ## Stream error logs for Galera (Usage: make follow-error-galera [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "galera_02";; 3) echo "galera_03";; *) echo "galera_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "galera02";; 3) echo "galera03";; *) echo "galera01";; esac); \
	docker compose -f $(COMPOSE_GALERA) exec $$SERVICE tail -f /var/lib/mysql/$$HOST.err

logs-slow-galera: ## Read last 100 lines of slow query logs for Galera (Usage: make logs-slow-galera [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "galera_02";; 3) echo "galera_03";; *) echo "galera_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "galera02";; 3) echo "galera03";; *) echo "galera01";; esac); \
	docker compose -f $(COMPOSE_GALERA) exec $$SERVICE tail -n 100 /var/lib/mysql/$$HOST-slow.log

follow-slow-galera: ## Stream slow query logs for Galera (Usage: make follow-slow-galera [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "galera_02";; 3) echo "galera_03";; *) echo "galera_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "galera02";; 3) echo "galera03";; *) echo "galera01";; esac); \
	docker compose -f $(COMPOSE_GALERA) exec $$SERVICE tail -f /var/lib/mysql/$$HOST-slow.log

logs-error-repli: ## Read last 100 lines of error logs for Replication (Usage: make logs-error-repli [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "mariadb_02";; 3) echo "mariadb_03";; *) echo "mariadb_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "frm02";; 3) echo "frm03";; *) echo "frm01";; esac); \
	docker compose -f $(COMPOSE_REPLI) exec $$SERVICE tail -n 100 /var/lib/mysql/$$HOST.err

follow-error-repli: ## Stream error logs for Replication (Usage: make follow-error-repli [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "mariadb_02";; 3) echo "mariadb_03";; *) echo "mariadb_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "frm02";; 3) echo "frm03";; *) echo "frm01";; esac); \
	docker compose -f $(COMPOSE_REPLI) exec $$SERVICE tail -f /var/lib/mysql/$$HOST.err

logs-slow-repli: ## Read last 100 lines of slow query logs for Replication (Usage: make logs-slow-repli [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "mariadb_02";; 3) echo "mariadb_03";; *) echo "mariadb_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "frm02";; 3) echo "frm03";; *) echo "frm01";; esac); \
	docker compose -f $(COMPOSE_REPLI) exec $$SERVICE tail -n 100 /var/lib/mysql/$$HOST-slow.log

follow-slow-repli: ## Stream slow query logs for Replication (Usage: make follow-slow-repli [NODE=1|2|3])
	@SERVICE=$$(case "$(NODE)" in 2) echo "mariadb_02";; 3) echo "mariadb_03";; *) echo "mariadb_01";; esac); \
	HOST=$$(case "$(NODE)" in 2) echo "frm02";; 3) echo "frm03";; *) echo "frm01";; esac); \
	docker compose -f $(COMPOSE_REPLI) exec $$SERVICE tail -f /var/lib/mysql/$$HOST-slow.log
