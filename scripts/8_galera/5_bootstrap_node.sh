#!/bin/bash
set -euo pipefail

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
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
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
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/my.cnf.d/" ] && CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/conf.d/" ] && CONF_FILE="//mysqetcl/conf.d/999_galera_settings.cnf"
[ -d "/etc/mysql/mariadb.conf.d/" ] && CONF_FILE="/etc/mysql/mariadb.conf.d/999_galera_settings.cnf"

DATADIR=/var/lib/mysql/
# --- Cluster Configuration (Defaults) ---
# It is STRONGLY RECOMMENDED to override these in /etc/bootstrap.conf
cluster_name="${cluster_name:-"generic"}"
node_addresses="${node_addresses:-"192.168.56.191,192.168.56.192,192.168.56.193"}"
sst_user="${sst_user:-"galera"}"
sst_password="${sst_password:-"kee2iesh1Ohk1puph8"}" # Default (Insecure)

[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf

if [ "$sst_password" = "kee2iesh1Ohk1puph8" ]; then
    warn "USING DEFAULT INSECURE SST PASSWORD. Please define sst_password in /etc/bootstrap.conf"
fi


##title_en: Galera Cluster bootstrap
##title_fr: Initialisation du cluster Galera
##goals_en: Start  a 1st operationnal node /  Start a consistent first node / Galera Cluster initialisation
##goals_fr: Démarrer un 1ere nœud Galera opérationnel / Démarrer un nœud dans un état consistant  / Initialiser un cluster Galera

[ -f "/usr/lib/galera/libgalera_smm.so" ] && GALERA_LIB=/usr/lib/galera/libgalera_smm.so
[ -f "/usr/lib64/galera-4/libgalera_smm.so" ] && GALERA_LIB=/usr/lib64/galera-4/libgalera_smm.so

banner "BEGIN SCRIPT: ${_NAME}"

cmd "rm -f $CONF_FILE"

info "SETUP $(basename $CONF_FILE) FILE INTO $(dirname $CONF_FILE)"

#title2 "ADDING PASSWORD FOR $sst_user DURING BOOTSTRAP"
#timeout 5 mysql -e "SET PASSWORD FOR '${sst_user}'@'localhost' = PASSWORD('${sst_password}')"


(
echo "# Minimal Galera configuration - created $(date)
[server]
binlog-format=ROW
default-storage-engine=innodb

innodb-autoinc-lock-mode=2
innodb-flush-log-at-trx-commit = 1
innodb_locks_unsafe_for_binlog = 1
innodb-force-primary-key=1

sync-binlog=0

wsrep-on=on
wsrep-provider=$GALERA_LIB
wsrep-slave-threads=$(( $(nproc) * 4 ))

wsrep_log_conflicts=ON

wsrep-cluster-name=${cluster_name}
wsrep-node-name=${node_name}
wsrep-node-address=${private_ip}
wsrep-cluster-address=gcomm://${node_addresses}
#wsrep-cluster-address=gcomm://

wsrep-sst-method=mariabackup

wsrep_sst_receive_address=${private_ip}
wsrep-sst-auth=${sst_user}:${sst_password}
#wsrep-notify-cmd=/opt/local/bin/table_wsrep_notif.sh
wsrep-notify-cmd=/opt/local/bin/file_wsrep_notif.sh

# Provider options
#wsrep_provider_options='socket.ssl_cert=/etc/mysql/ssl/server-cert.pem;socket.ssl_ca=/etc/mysql/ssl/ca-cert.pem;socket.ssl_key=/etc/mysql/ssl/server-key.pem'
#wsrep_provider_options='socket.ssl_cipher=AES128-SHA'
wsrep-provider-options='gcache.size=512M;cert.log_conflicts=yes;gcs.fc_factor=0.8;gcs.fc_limit=254'
#wsrep-provider-options='gcache.size=512M;cert.log_conflicts=yes;gcs.fc_factor=0.8;gcs.fc_limit=254;socket.ssl_cert=/etc/mysql/ssl/server-cert.pem;socket.ssl_ca=/etc/mysql/ssl/ca-cert.pem;socket.ssl_key=/etc/mysql/ssl/server-key.pem;socket.ssl_cipher=AES128-SHA'

#wsrep_debug=1


[sst]
#streamfmt=mbstream
compressor='pigz'
decompressor='pigz -dc'

[mariabackup]
parallel=$(nproc)
"
) | tee -a $CONF_FILE


cmd "chmod 644 $CONF_FILE"

cmd "systemctl stop mariadb"

cmd "rm -f ${DATADIR}/galera.cache ${DATADIR}/grastate.dat ${DATADIR}/gvwstate.dat" "CLEANUP GALERA STATE"
cmd "/usr/bin/galera_new_cluster" "BOOTSTRAP NEW CLUSTER"

cmd "echo \"install soname 'wsrep_info';\"| mysql -v" "INSTALL WSREP_INFO"
cmd "echo \"select * from information_schema.wsrep_status\G\" |mysql" "CHECK WSREP STATUS"
cmd "echo \"select * from information_schema.wsrep_membership;\" | mysql" "CHECK WSREP MEMBERSHIP"

cmd "tail -n 30 /var/log/mysql/mysqld.log" "SHOW RECENT LOGS"
#set -x
for srv in $(echo $node_addresses | tr ',' ' ' ) ;do
	[ "$private_ip" == "$srv" ] && continue
	info "COPYING /etc/bootstrap.conf TO $srv"
	scp -o "StrictHostKeyChecking=no" /etc/bootstrap.conf root@$srv:/etc 2>/dev/null
done
#set +x

footer "END SCRIPT: ${_NAME}"
exit $lRC
