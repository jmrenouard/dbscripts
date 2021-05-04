#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
CONF_SRV_FILE="/etc/my.cnf.d/99_minimal_ssl_config.cnf"
CONF_CLI_FILE="/etc/my.cnf.d/50-mysql_ssl_clients.cnf"

banner "BEGIN SCRIPT: $_NAME"


mkdir -p /etc/mysql/ssl
cd /etc/mysql/ssl

# CA Key
openssl genrsa 4096 > ca-key.pem

#CA Certificate
openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem


# Génération des clés pour le serveur
openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem
openssl rsa -in server-key.pem -out server-key.pem

# Certificat SSL pour le serveur
openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# Génération des clés pour le client
openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client-key.pem -out client-req.pem
openssl rsa -in client-key.pem -out client-key.pem

# Certificat SSL pour le client
openssl x509 -req -in client-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

chown -Rv mysql:root /etc/mysql/ssl/

# Vérification
openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem

echo "[mysqld]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
## Set up TLS version here. For example TLS version 1.2 and 1.3 ##
tls_version = TLSv1.2,TLSv1.3"| tee $CONF_SRV_FILE


echo "[mysql]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/client-cert.pem
ssl-key=/etc/mysql/ssl/client-key.pem
"| tee $CONF_CLI_FILE
/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf
tar czf client_certificates.tgz ca-cert.pem client-cert.pem client-key.pem

systemctl restart mariadb

footer "END SCRIPT: $NAME"
exit $lRC
