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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

lRC=0

banner "BEGIN SCRIPT: ${_NAME}"

CONF_FILE="/etc/haproxy/haproxy.cfg"

cluster_name="gendarmerie"
node_addresses=192.168.56.191,192.168.56.192,192.168.56.193

[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf
[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf

PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"

cmd "$PCKMANAGER -y update"
#cmd "$PCKMANAGER -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"

cmd "$PCKMANAGER -y install haproxy"
cmd "$PCKMANAGER -y install socat keepalived"

[ "$ID" = "ubuntu" -o "$ID" = "debian" ] || cmd "setenforce 0"

CERT_DIR=${1:-"/etc/haproxy/ssl"}
CRT_INFO=${2:-"ST=FR/C=FR/L=Rennes/O=Lightpath/OU=DSI"}

CRT_CA_INFO="/CN=$(hostname -s)-CASERVER/$CRT_INFO/"
CRT_SERVER_INFO="/CN=$(hostname -s)/$CRT_INFO/"


[ -d "$CERT_DIR" ] || mkdir -p $CERT_DIR
rm -f ${CERT_DIR}/*

cd $CERT_DIR

if [ ! -f "ca-key.pem" ]; then
	openssl genrsa 2048 | tee ca-key.pem
fi 

if [ ! -f "ca-key.csr" ]; then
	openssl req -new -key ca-key.pem -out ca-key.csr  -subj "$CRT_SERVER_INFO"
fi

if [ ! -f "ca-server.crt" ]; then
	openssl x509 -req -days 365 -in ca-key.csr -signkey ca-key.pem -out ca-server.crt
fi	

if [ ! -f "server-key.pem" ]; then 
	cat ca-key.pem ca-server.crt | tee server-cert.pem
fi

cmd "rm -f $CONF_FILE"
(
echo "global
        log /dev/log local1 notice
        chroot /var/lib/haproxy
        stats socket /tmp/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

defaults
        log global
        mode http
        timeout connect 5000
        timeout client 50000
        timeout server 50000

listen galera_cluster_backend
        mode tcp
        option tcpka
        timeout client 1m
        bind *:3306 #ssl crt /etc/haproxy/ssl/server-cert.pem
        balance leastconn
        # balance source
        # balance roundrobin
        # option mysql-check user haproxy
        option httpchk
        timeout connect 3s
        timeout server 1m"
for srv in $(echo $node_addresses | perl -pe 's/,/ /g'); do
	node_id=$(echo $srv | cut -d. -f4| perl -pe 's/\d+(\d)$/$1/')
	echo "	server mariadb${node_id} ${srv}:3306 check port 9200 inter 12000 rise 3 fall 3 weight 1"
done

echo "
frontend stats
        bind *:3310  ssl crt /etc/haproxy/ssl/server-cert.pem
        mode http
        log global
        maxconn 10
        #timeout queue 100s
        stats enable
        stats admin if TRUE
        stats hide-version
        stats refresh 10s
        stats show-node
        stats auth admin:password
        stats uri /haproxy
"
) | tee -a $CONF_FILE


cmd "chmod 644 $CONF_FILE"

cmd "systemctl enable haproxy"
cmd "systemctl restart haproxy"



firewall-cmd --add-port=3310/tcp --permanent
firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload

cmd "netstat -ltpn | grep 3306"
lRC=$(($lRC + $?))

cmd "netstat -ltpn | grep 3310"
lRC=$(($lRC + $?))

cmd "systemctl status haproxy"
lRC=$(($lRC + $?))

footer "END SCRIPT: ${_NAME}"
exit $lRC