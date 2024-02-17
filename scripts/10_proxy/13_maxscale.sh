#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.8"}
rpm_url="https://dlm.mariadb.com/2468261/MaxScale/22.08.1/centos/7Server/x86_64/maxscale-22.08.1-1.rhel.7.x86_64.rpm"

lRC=0

banner "BEGIN SCRIPT: $_NAME"

if [ "$ID" != "ubuntu" ]; then
     cmd 'rm -f /etc/yum.repos.d/mariadb_*.repo'

     info "SETUP mariadb_${VERSION}.repo FILE"
     echo "# MariaDB $VERSION CentOS repository list - created $(date)
     # http://downloads.mariadb.org/mariadb/repositories/
     [mariadb]
     name = MariaDB_$VERSION
     baseurl = http://yum.mariadb.org/$VERSION/centos${VERSION_ID}-amd64
     module_hotfixes=1
     gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
     gpgcheck=1" > "/etc/yum.repos.d/mariadb_${VERSION}.repo"

     cmd "cat /etc/yum.repos.d/mariadb_${VERSION}.repo"

     cmd "yum -y install $rpm_url"
else
     cmd "apt -y install wget"
     cd /tmp
     cmd "wget https://dlm.mariadb.com/2700577/MaxScale/22.08.3/packages/ubuntu/jammy/x86_64/maxscale-22.08.3-1.ubuntu.jammy.x86_64.deb"
     cd /root
     cmd "apt -y install /tmp/maxscale-22.08.3-1.ubuntu.jammy.x86_64.deb"

     cmd "apt install -y firewalld python3-firewall"
	cmd "timeout 10 systemctl restart"
	cmd "timeout 10 systemctl enable firewalld"
	cmd "firewall-cmd --add-port=4006/tcp --permanent"
     cmd "firewall-cmd --add-port=4008/tcp --permanent"
     cmd "firewall-cmd --reload"
     cmd "firewall-cmd --list-all"
fi

MYSQL_IP_FILTERS="192.168.%,172.21.%,172.20.%"
MAXSCALE_PASSWORD=$(pwgen -1 32)

for MYSQL_IP_FILTER in $(echo "$MYSQL_IP_FILTERS"| tr ',' ' '); do
echo "DROP user IF EXISTS 'maxscale'@'$MYSQL_IP_FILTER';
create user 'maxscale'@'$MYSQL_IP_FILTER' identified by '${MAXSCALE_PASSWORD}';
grant select on mysql.user to 'myuser'@'$MYSQL_IP_FILTER';
GRANT SHOW DATABASES ON *.* TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.columns_priv TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.db TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.proxies_priv TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.procs_priv TO 'mxs'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.roles_mapping TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.tables_priv TO 'maxscale'@'$MYSQL_IP_FILTER';
GRANT SELECT ON mysql.user TO 'maxscale'@'$MYSQL_IP_FILTER';"
done > "/etc/maxscale.sql"

echo "
# Globals
[maxscale]
threads=auto
syslog=0
maxlog=1
log_to_shm=1
log_warning=1
log_notice=1
log_info=1
log_debug=0
logdir=/var/log/maxscale/
datadir=/var/lib/maxscale/

# Servers
[node1]
type=server
address=172.20.0.101
port=3306
protocol=MariaDBBackend

[node2]
type=server
address=172.20.0.102
port=3306
protocol=MariaDBBackend

[node3]
type=server
address=172.20.0.103
port=3306
protocol=MariaDBBackend

# Monitoring for the servers
[Galera Monitor]
type=monitor
module=galeramon
servers=node1,node2,node3
user=maxscale
passwd=${MAXSCALE_PASSWORD}
monitor_interval=1000

# Galera router service
[Galera Service]
type=service
router=readwritesplit
servers=node1,node2,node3
user=maxscale
passwd=${MAXSCALE_PASSWORD}

# MaxAdmin Service
[MaxAdmin Service]
type=service
router=cli

# Galera cluster listener
[Galera Listener]
type=listener
service=Galera Service
protocol=MySQLClient
port=3306

# MaxAdmin listener
[MaxAdmin Listener]
type=listener
service=MaxAdmin Service
protocol=maxscaled
socket=default" > /etc/maxscale.cnf

ssh -o "StrictHostKeyChecking=no" node1.local "cat .my.cnf" > .my.cnf
echo "host=node1.local" >> .my.cnf

mysql -e 'status'
if [ $? -eq 0 ]; then
  cat /etc/maxscale.sql | ssh -o "StrictHostKeyChecking=no" node1.local mysql -f -v
fi

cmd "dpkg -L maxscale"

cmd "systemctl enable maxscale"
cmd "systemctl start maxscale"



footer "END SCRIPT: $NAME"
exit $lRC
