#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"15"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: $_NAME"

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
lRC=$(($lRC + $?))

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
lRC=$(($lRC + $?))

cmd "apt update" "Update package info...."
lRC=$(($lRC + $?))

# Install PostgreSQL:
cmd  "apt install -y postgresql-${VERSION} postgresql-${VERSION}-hypopg postgresql-${VERSION}-mysql-fdw postgresql-15-pg-checksums postgresql-15-pg-catcheck"
lRC=$(($lRC + $?))

cmd  "apt install -y postgresql-${VERSION}-pgaudit postgresql-${VERSION}-postgis-3 postgresql-${VERSION}-postgis-3-scripts postgresql-${VERSION}-plsh"
lRC=$(($lRC + $?))

cmd "apt -y install python3 pgbackrest pgbadger htop telnet"
lRC=$(($lRC + $?))

cmd "apt -y install nagios-nrpe-server nagios-nrpe-plugin centreon-plugins monitoring-plugins monitoring-plugins-contrib nagios-snmp-plugins"
lRC=$(($lRC + $?))

cmd "apt -y install cracklib-runtime python3-cracklib sysbench tree telnet netcat-openbsd netcat libjemalloc2 libdbi-perl libdbd-mysql-perl"
lRC=$(($lRC + $?))

cmd "apt -y install rsync nmap lsof pigz git pwgen net-tools"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC