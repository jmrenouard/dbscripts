#!/bin/bash
set -e

DATA_DIR="/var/lib/mysql"

echo ">> Vérification de l'état de la base de données dans $DATA_DIR..."

# 1. Vérifie si la base 'mysql' existe (signe d'une installation déjà faite)
if [ ! -d "$DATA_DIR/mysql" ]; then
    echo ">> ⚠️ Première exécution détectée. Initialisation de la base de données..."
    
    # Initialisation de la DB system
    # --auth-root-authentication-method=normal permet de se connecter en root avec mot de passe si besoin
    mariadb-install-db --user=root --datadir="$DATA_DIR"
    
    echo ">> ✅ Initialisation terminée."
else
    echo ">> ✅ Données existantes détectées. Démarrage normal."
fi

# 2. Démarrage du démon en mode 'safe'
# Note: On laisse mysqld_safe gérer le processus. 
# Supervisor s'attend à ce que le script ne rende pas la main (foreground),
# mais mysqld_safe lance un background process par défaut.
# Pour Supervisor, il vaut mieux lancer mariadbd directement ou utiliser exec.

echo ">> 🚀 Démarrage de MariaDB Safe..."
exec mariadbd-safe --datadir="$DATA_DIR" --user=root
