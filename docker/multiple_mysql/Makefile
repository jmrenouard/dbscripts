# Makefile pour orchestrer les conteneurs de bases de données via Docker Compose

# --- Configuration ---
# Utilise le shell bash pour des fonctionnalités plus riches
SHELL := /bin/bash

# --- Cibles principales ---
.PHONY: help mysql93 mysql84 mysql80 mariadb114 mariadb1011 mariadb106 percona84 percona80 stop status logs

# Cible par défaut, affiche l'aide
help:
	@echo "╔═══════════════════════════════════════════════════════╗"
	@echo "║      🚀 Commandes disponibles pour gérer les BDD      ║"
	@echo "╚═══════════════════════════════════════════════════════╝"
	@echo ""
	@echo "  \033[1;33mUtilisation:\033[0m make <commande>"
	@echo ""
	@echo "  \033[1;32mGénéral:\033[0m"
	@echo "    \033[1mstop\033[0m          - 🛑 Arrête tous les conteneurs gérés par ce projet."
	@echo "    \033[1mstatus\033[0m        - 📊 Affiche le statut des conteneurs actifs."
	@echo "    \033[1mlogs\033[0m          - 📄 Affiche les logs de tous les conteneurs (ex: make logs service=mysql93)."
	@echo ""
	@echo "  \033[1;32mMySQL:\033[0m"
	@echo "    \033[1mmysql93\033[0m       - Lance MySQL 9.3"
	@echo "    \033[1mmysql84\033[0m       - Lance MySQL 8.4"
	@echo "    \033[1mmysql80\033[0m       - Lance MySQL 8.0"
	@echo ""
	@echo "  \033[1;32mMariaDB:\033[0m"
	@echo "    \033[1mmariadb114\033[0m    - Lance MariaDB 11.4"
	@echo "    \033[1mmariadb1011\033[0m   - Lance MariaDB 10.11"
	@echo "    \033[1mmariadb106\033[0m    - Lance MariaDB 10.6"
	@echo ""
	@echo "  \033[1;32mPercona Server:\033[0m"
	@echo "    \033[1mpercona84\033[0m     - Lance Percona Server 8.4"
	@echo "    \033[1mpercona80\033[0m     - Lance Percona Server 8.0"
	@echo ""

# --- Commandes de gestion ---

# 🛑 Arrête et supprime tous les conteneurs, réseaux et orphelins
stop:
	@echo "🔥 Arrêt et nettoyage des conteneurs..."
	@docker compose down --remove-orphans

# 📊 Affiche le statut des conteneurs
status:
	@echo "📊 Statut des conteneurs Docker Compose :"
	@docker compose ps

# 📄 Affiche les logs
# Utilisation : make logs ou make logs service=<nom_du_service>
service ?= ""
logs:
	@echo "📄 Affichage des logs..."
	@docker compose logs -f $(service)

# --- Cibles de démarrage par profil ---

# 🐬 MySQL
mysql93: stop
	@echo "🚀 Démarrage de MySQL 9.3..."
	@docker compose --profile mysql93 up -d

mysql84: stop
	@echo "🚀 Démarrage de MySQL 8.4..."
	@docker compose --profile mysql84 up -d

mysql80: stop
	@echo "🚀 Démarrage de MySQL 8.0..."
	@docker compose --profile mysql80 up -d

# 🐧 MariaDB
mariadb114: stop
	@echo "🚀 Démarrage de MariaDB 11.4..."
	@docker compose --profile mariadb114 up -d

mariadb1011: stop
	@echo "🚀 Démarrage de MariaDB 10.11..."
	@docker compose --profile mariadb1011 up -d

mariadb106: stop
	@echo "🚀 Démarrage de MariaDB 10.6..."
	@docker compose --profile mariadb106 up -d

# ⚡ Percona Server
percona84: stop
	@echo "🚀 Démarrage de Percona Server 8.4..."
	@docker compose --profile percona84 up -d

percona80: stop
	@echo "🚀 Démarrage de Percona Server 8.0..."
	@docker compose --profile percona80 up -d
# --- Fin du Makefile ---
