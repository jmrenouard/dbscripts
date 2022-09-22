#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.8"}
rpm_url="https://dlm.mariadb.com/2468261/MaxScale/22.08.1/centos/7Server/x86_64/maxscale-22.08.1-1.rhel.7.x86_64.rpm"

lRC=0

banner "BEGIN SCRIPT: $_NAME"

cmd 'rm -f /etc/yum.repos.d/mariadb_*.repo'

info "SETUP mariadb_${VERSION}.repo FILE"
echo "# MariaDB $VERSION CentOS repository list - created $(date)
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB_$VERSION
baseurl = http://yum.mariadb.org/$VERSION/centos${VERSION_ID}-amd64
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/mariadb_${VERSION}.repo

cmd "cat /etc/yum.repos.d/mariadb_${VERSION}.repo"

cmd "yum -y install $rpm_url"

echo "create user 'maxscale'@'192.168.%' identified by 'maxscale';
grant select on mysql.user to 'myuser'@'192.168.%';
GRANT SHOW DATABASES ON *.*
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.columns_priv
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.db
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.proxies_priv
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.procs_priv
     TO 'mxs'@'192.168.%';
GRANT SELECT ON mysql.roles_mapping
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.tables_priv
     TO 'maxscale'@'192.168.%';
GRANT SELECT ON mysql.user
     TO 'maxscale'@'192.168.%';"

echo "
# Globals
[maxscale]
threads=1
 
# Servers
[node0]
type=server
address=192.168.56.100
port=3306
protocol=MySQLBackend
 
[node1]
type=server
address=192.168.56.101
port=3306
protocol=MySQLBackend
 
[node2]
type=server
address=192.168.56.102
port=3306
protocol=MySQLBackend
 
# Monitoring for the servers
[Galera Monitor]
type=monitor
module=galeramon
servers=node0,node1,node2
user=maxscale
passwd=maxscale
monitor_interval=1000
 
# Galera router service
[Galera Service]
type=service
router=readwritesplit
servers=node0,node1,node2
user=maxscale
passwd=maxscale
 
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
footer "END SCRIPT: $NAME"
exit $lRC