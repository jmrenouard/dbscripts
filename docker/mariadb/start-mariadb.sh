#!/bin/bash
set -e

DATA_DIR="/var/lib/mysql"

echo ">> Vérification de l'état de la base de données dans $DATA_DIR..."

# 1. Vérifie si la base 'mysql' existe (signe d'une installation déjà faite)
if [ ! -d "$DATA_DIR/mysql" ]; then
    echo ">> ⚠️ Première exécution détectée. Initialisation de la base de données..."
    
    # Initialisation de la DB system
    mariadb-install-db --user=root --datadir="$DATA_DIR"
    
    echo ">> ✅ Initialisation terminée."

    # Execute initialization scripts
    if [ -d "/docker-entrypoint-initdb.d" ]; then
        echo ">> 📜 Exécution des scripts d'initialisation..."
        mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld || true
        
        SOCKET="/run/mysqld/mysqld_init.sock"
        # Start temporary MariaDB to apply permissions
        mariadbd --user=root --datadir="$DATA_DIR" --skip-networking --wsrep-on=OFF --socket="$SOCKET" &
        pid="$!"
        
        # Wait for MariaDB to be ready (with timeout)
        COUNTER=0
        until mariadb --socket="$SOCKET" -u root -e "SELECT 1" >/dev/null 2>&1 || [ $COUNTER -eq 30 ]; do
            echo ">> ⏳ Attente de MariaDB ($COUNTER/30)..."
            sleep 1
            let COUNTER=COUNTER+1
        done
        
        if [ $COUNTER -eq 30 ]; then
            echo ">> ❌ Timeout en attendant MariaDB pour l'initialisation."
            kill -s TERM "$pid" || true
            exit 1
        fi

        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sql)    echo ">> 🚀 Exécution de $f..."; mariadb --socket="$SOCKET" -u root < "$f"; echo ;;
                *)        echo ">> ⏭️ Ignoré: $f" ;;
            esac
        done
        
        # Shutdown temporary MariaDB
        echo ">> 🛑 Arrêt de la MariaDB temporaire..."
        mariadb-admin --socket="$SOCKET" -u root shutdown || kill -s TERM "$pid" || true
        wait "$pid" || true
    fi
else
    echo ">> ✅ Données existantes détectées. Démarrage normal."
fi

# 2. Démarrage du démon en mode 'safe'
# Note: On laisse mysqld_safe gérer le processus. 
# Supervisor s'attend à ce que le script ne rende pas la main (foreground),
# mais mysqld_safe lance un background process par défaut.
# Pour Supervisor, il vaut mieux lancer mariadbd directement ou utiliser exec.

echo ">> 🚀 Démarrage de MariaDB Safe..."
EXTRA_ARGS=""
if [ "$MARIADB_GALERA_BOOTSTRAP" = "1" ]; then
    echo ">> 🌟 Bootstrapping de nouveaux clusters Galera détecté..."
    # Force safe_to_bootstrap=1 in grastate.dat if it exists
    if [ -f "$DATA_DIR/grastate.dat" ]; then
        echo ">> 🛠️ Forçage de safe_to_bootstrap=1 dans grastate.dat"
        sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/' "$DATA_DIR/grastate.dat"
    fi
    EXTRA_ARGS="--wsrep-new-cluster"
fi

exec mariadbd-safe --datadir="$DATA_DIR" --user=root $EXTRA_ARGS
