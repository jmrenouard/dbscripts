#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "BEGIN SCRIPT: $_NAME"

CONF_FILE="/etc/haproxy/haproxy.cfg"

cluster_name="gendarmerie"
node_addresses=192.168.56.191,192.168.56.192,192.168.56.193

[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf
source /etc/os-release

PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"

cmd "$PCKMANAGER -y update"
#cmd "$PCKMANAGER -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"

cmd "$PCKMANAGER -y install haproxy"
cmd "$PCKMANAGER -y install socat keepalived"

cmd "setenforce 0"

CERT_DIR=${1:-"/etc/haproxy/ssl"}
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
        bind *:3306 ssl crt /etc/haproxy/ssl/server-cert.pem
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
        bind *:3310  ssl crt /etc/haproxy/ssl/server-key.pem
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

footer "END SCRIPT: $NAME"
exit $lRC