#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
CONF_FILE="/etc/my.cnf.d/999_galera_settings.cnf"
DATADIR=/var/lib/mysql/
cluster_name="opencluster"
server_id=$(hostname -s| perl -pe 's/.+?(\d+)/$1/')
node_name=$(hostname -s)
private_ip=$(ip a| grep '192' |grep inet|awk '{print $2}'| cut -d/ -f1)
node_addresses=192.168.33.161,192.168.33.162,192.168.33.163,192.168.33.164
sst_user=galera
sst_password=ohGh7boh7eeg6shuph

banner "BEGIN SCRIPT: $_NAME"

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
innodb-flush-log-at-trx-commit = 0

wsrep-on=on
wsrep-provider=/usr/lib64/galera-4/libgalera_smm.so

wsrep-cluster-name=${cluster_name}
wsrep-node-name=${node_name}
wsrep-node-address=${private_ip}
wsrep-cluster-address=gcomm://${node_addresses}
#wsrep-cluster-address=gcomm://

wsrep-sst-method=mariabackup
wsrep-sst-auth=${sst_user}:${sst_password}
#wsrep-notify-cmd=/opt/local/bin/table_wsrep_notif.sh
"
) | tee -a $CONF_FILE

cmd "chmod 644 $CONF_FILE"

cmd "systemctl stop mariadb"

cmd "rm -f ${DATADIR}/galera.cache ${DATADIR}/grastate.dat ${DATADIR}/gvwstate.dat
"
cmd "/usr/bin/galera_new_cluster"

echo "install soname 'wsrep_info';"| mysql -v
echo "select * from information_schema.wsrep_status\G" |mysql
echo "select * from information_schema.wsrep_membership;" | mysql 

footer "END SCRIPT: $NAME"
exit $lRC