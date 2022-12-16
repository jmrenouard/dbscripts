#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh

lRC=0
[ -d "/etc/my.cnf.d/" ] && CONF_CLI_FILE="/etc/my.cnf.d/50-mysql_ssl_clients.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_CLI_FILE="/etc/mysql/conf.d/50-mysql_ssl_clients.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_CLI_FILE="/etc/mysql/mariadb.d/50-mysql_ssl_clients.cnf"

banner "BEGIN SCRIPT: $_NAME"

[ -d "/etc/mysql/ssl" ] || mkdir -p /etc/mysql/ssl
cd /etc/mysql/ssl

if [ ! -f "ca-key.pem" ]; then
    # CA Key
    openssl genrsa 4096 > ca-key.pem
fi

if [ ! -f "ca-cert.pem" ]; then
    #CA Certificate
    openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem
fi

# Génération des clés pour le client
openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client-key.pem -out client-req.pem
openssl rsa -in client-key.pem -out client-key.pem

# Certificat SSL pour le client
openssl x509 -req -in client-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

chown -Rv mysql:root /etc/mysql/ssl/

# Vérification
openssl verify -CAfile ca-cert.pem client-cert.pem

echo "[mysql]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/client-cert.pem
ssl-key=/etc/mysql/ssl/client-key.pem
"| tee $CONF_CLI_FILE
/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf

tar czf client_certificates.tgz ca-cert.pem client-cert.pem client-key.pem

mysql -v -e "FLUSH SSL"

footer "END SCRIPT: $NAME"
exit $lRC