#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh

lRC=0
[ -d "/etc/my.cnf.d/" ] && CONF_SRV_FILE="/etc/my.cnf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_SRV_FILE="/etc/mysql/conf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_SRV_FILE="/etc/mysql/mariadb.d/99_minimal_ssl_config.cnf"

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

# Génération des clés pour le serveur
openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem
openssl rsa -in server-key.pem -out server-key.pem

# Certificat SSL pour le serveur
openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

chown -Rv mysql:root /etc/mysql/ssl/

# Vérification
openssl verify -CAfile ca-cert.pem server-cert.pem

echo "[mysqld]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
## Set up TLS version here. For example TLS version 1.2 and 1.3 ##
tls_version = TLSv1.2,TLSv1.3"| tee $CONF_SRV_FILE

mysql -v -e "FLUSH SSL"

footer "END SCRIPT: $NAME"
exit $lRC

# AL