#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "BEGIN SCRIPT: $_NAME"

CONF_FILE="/etc/haproxy/haproxy.cfg"

cluster_name="meteocluster"
node_addresses=192.168.33.173,192.168.33.174,192.168.33.175


cmd "yum -y install haproxy"

cmd "setenforce 0"

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
        bind *:3306
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
        bind *:3310
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

cmd "systemctl restart haproxy"

footer "END SCRIPT: $NAME"
exit $lRC