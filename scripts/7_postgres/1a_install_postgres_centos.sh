#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"13"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: $_NAME"


cmd  "dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"
lRC=$(($lRC + $?))

# Install the repository RPM:
cmd  "dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-${VERSION_ID}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
lRC=$(($lRC + $?))

# Disable the built-in PostgreSQL module:
cmd "dnf -qy module disable postgresql"
lRC=$(($lRC + $?))
# Install PostgreSQL:
cmd  "dnf install -y postgresql${VERSION} postgresql${VERSION}-server postgresql${VERSION}-contrib"
lRC=$(($lRC + $?))


cmd "dnf -y install python3 pgbackrest pgbadger htop nrpe nagios-plugins-nrpe nagios-plugins-all"
lRC=$(($lRC + $?))

cmd "dnf -y install cracklib cracklib-dicts tree socat sysbench jemalloc rsync nmap lsof perl-DBI nc  pigz perl-DBD-MySQL git pwgen"
lRC=$(($lRC + $?))


footer "END SCRIPT: $NAME"
exit $lRC