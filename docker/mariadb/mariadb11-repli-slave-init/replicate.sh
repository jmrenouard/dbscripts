#!/bin/bash
set -e
set -x

MYSQL=mariadb
MYSQLDUMP=mariadb-dump

# Charger les variables du fichier .env
if [ -f "/docker-entrypoint-initdb.d/.env" ]; then
    export $(grep -v '^#' /docker-entrypoint-initdb.d/.env | xargs)
fi
echo "Attente de la disponibilité du master..."
until $MYSQL -h master -uroot -p${ROOT_PASSWORD} -e "SELECT 1" &> /dev/null
do
  sleep 1
done

echo "Le master est prêt, préparation de la réplication..."

# Dump des données du master
$MYSQLDUMP -h master -uroot -p${ROOT_PASSWORD} --all-databases --single-transaction --master-data=1 | \
$MYSQL -uroot -p${ROOT_PASSWORD}

$MYSQL -h master -uroot -p${ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"
# Récupération des informations du master
MASTER_STATUS=$($MYSQL -h master -uroot -p${ROOT_PASSWORD} -e "SHOW MASTER STATUS\G" | grep -E 'File|Position')
LOG_FILE=$(echo "$MASTER_STATUS" | grep 'File:' | awk '{print $2}')
LOG_POS=$(echo "$MASTER_STATUS" | grep 'Position:' | awk '{print $2}')

# Configuration de l'esclave
$MYSQL -uroot -p${ROOT_PASSWORD} -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='${REPL_USER}', MASTER_PASSWORD='${REPL_PASSWORD}', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS; START SLAVE;"

# Validation de la réplication
$MYSQL -uroot -p${ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"