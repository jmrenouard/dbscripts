#!/bin/bash

source /etc/os-release

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"

lRC=0
[ -d "/etc/my.cnf.d/" ] && CONF_SRV_FILE="/etc/my.cnf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_SRV_FILE="/etc/mysql/conf.d/99_minimal_ssl_config.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_SRV_FILE="/etc/mysql/mariadb.conf.d/99_minimal_ssl_config.cnf"

banner "BEGIN SCRIPT: ${_NAME}"

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
    footer "END SCRIPT: ${_NAME}"
    exit 1
fi

rm -f sst*
openssl genrsa 2048 > sst-ca-key.pem
openssl req -new -x509 -nodes -days 365000 \
-key sst-ca-key.pem -out sst-ca-cert.pem -subj "$CRT_CA_INFO"
 
# sst server
openssl req -newkey rsa:2048 -days 365000 \
-nodes -keyout sst-server-key.pem -out sst-server-req.pem -subj "$CRT_SERVER_INFO"
openssl rsa -in sst-server-key.pem -out sst-server-key.pem
openssl x509 -req -in sst-server-req.pem -days 365000 \
-CA sst-ca-cert.pem -CAkey sst-ca-key.pem -set_serial 01 \
-out sst-server-cert.pem

#openssl genrsa -out sst.key 1024
#openssl req -new -key sst.key -x509 -days 36500 -out sst.crt -subj "$CRT_CA_INFO"
#cat sst.key sst.crt >sst.pem
#openssl dhparam -out dhparams.pem 2048
#cat dhparams.pem >> sst.pem
#chmod 600 sst-*.key sst-*.pem

if [[ ! -d "/etc/mysql/ssl" || "$CERT_DIR" != "/etc/mysql/ssl" ]]; then
    info "SIMPLE CERT GENERATION - NO MYSQL CONFIGURATION GENERATED"
    footer "END SCRIPT: ${_NAME}"
    exit 0
fi

chown -Rv mysql:root $CERT_DIR

echo "[mysqld]
ssl-ca=$CERT_DIR/ca-cert.pem
ssl-cert=$CERT_DIR/server-cert.pem
ssl-key=$CERT_DIR/server-key.pem
## Set up TLS version here. For example TLS version 1.2 and 1.3 ##
tls_version = TLSv1.2,TLSv1.3

[sst]
encrypt=3
tkey=$CERT_DIR/sst-server-key.pem
tcert=$CERT_DIR/sst-server-cert.pem

#encrypt=2
ssl-mode=VERIFY_IDENTITY
#sst-log-archive=1
#sst-log-archive-dir=/var/log/mysql/sst/
#tca=$CERT_DIR/sst.crt
#tcert=$CERT_DIR/sst.pem
#tkey=$CERT_DIR/sst.key

"| tee $CONF_SRV_FILE

mysql -v -e "FLUSH SSL"

footer "END SCRIPT: ${_NAME}"
exit $lRC
