#!/bin/bash
set -e
set -x

# Charger les variables du fichier .env
if [ -f "/docker-entrypoint-initdb.d/.env" ]; then
    export $(grep -v '^#' /docker-entrypoint-initdb.d/.env | xargs)
fi
# Générer le SQL dynamiquement
echo "

drop DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
USE ${DB_NAME};

CREATE TABLE test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(100)
);
INSERT INTO test (data) VALUES ('Hello from master');

CREATE USER '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';
FLUSH PRIVILEGES;
" | mysql -uroot -p${ROOT_PASSWORD} -f -v