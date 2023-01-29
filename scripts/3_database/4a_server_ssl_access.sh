#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0
[ -d "/etc/my.cnf.d/" ] && CONF_SRV_FILE="/etc/my.cnf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_SRV_FILE="/etc/mysql/conf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_SRV_FILE="/etc/mysql/mariadb.conf.d/99_minimal_ssl_config.cnf"

banner "BEGIN SCRIPT: $_NAME"

CERT_DIR=${1:-"/etc/mysql/ssl"}
CRT_INFO=${2:-"ST=FR/C=FR/L=Rennes/O=Lightpath/OU=DSI"}

CRT_CA_INFO="/CN=$(hostname -s)-CASERVER/$CRT_INFO/"
CRT_SERVER_INFO="/CN=$(hostname -s)/$CRT_INFO/"

[ -d "$CERT_DIR" ] || mkdir -p $CERT_DIR

cd $CERT_DIR

if [ ! -f "ca-key.pem" ]; then
    # CA Key
    info "CMD: openssl genrsa 2048"
    openssl genrsa 2048 > ca-key.pem
fi

if [ ! -f "ca-cert.pem" ]; then
    #CA Certificate
    info "CMD: openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem -subj $CRT_CA_INFO"
    openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem -subj "$CRT_CA_INFO"
fi

# Génération des clés pour le serveur
if [ ! -f "server-req.pem" ]; then
    info "CMD: openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem -subj $CRT_SERVER_INFO"
    openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server-key.pem -out server-req.pem -subj $CRT_SERVER_INFO
fi

if [ -f "server-key.pem" ];then
    info "CMD: openssl rsa -in server-key.pem -out server-key.pem"
    openssl rsa -in server-key.pem -out server-key.pem
fi
# Certificat SSL pour le serveur
if [ ! -f "server-cert.pem" ]; then
    info "CMD: openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem"
    openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
fi
#chmod -Rv 700 *

# Vérification
info "CMD: openssl verify -verbose -CAfile ca-cert.pem server-cert.pem"
openssl verify -verbose -CAfile ca-cert.pem server-cert.pem
if [ $? -ne 0 ]; then
    error "ERROR: SSL CERTIFICATE NOT VALID"
    footer "END SCRIPT: $NAME"
    exit 1
fi

if [[ ! -d "/etc/mysql/ssl" || "$CERT_DIR" != "/etc/mysql/ssl" ]]; then
    info "SIMPLE CERT GENERATION - NO MYSQL CONFIGURATION GENERATED"
    footer "END SCRIPT: $NAME"
    exit 0
fi

chown -Rv mysql:root $CERT_DIR

echo "[mysqld]
ssl-ca=$CERT_DIR/ca-cert.pem
ssl-cert=$CERT_DIR/server-cert.pem
ssl-key=$CERT_DIR/server-key.pem
## Set up TLS version here. For example TLS version 1.2 and 1.3 ##
tls_version = TLSv1.2,TLSv1.3"| tee $CONF_SRV_FILE

mysql -v -e "FLUSH SSL"

footer "END SCRIPT: $NAME"
exit $lRC
