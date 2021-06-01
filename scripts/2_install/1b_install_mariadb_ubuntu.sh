#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.5"}

banner "BEGIN SCRIPT: $_NAME"

find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

if [ "$VERSION_CODENAME" = "groovy" ];then
	cmd "apt-get install software-properties-common" "ADDING SOFTWARE PROPERTIES"
	apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
	add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/$VERSION/ubuntu $VERSION_CODENAME main"
fi
cmd "apt -y update" "UPDATE PACKAGE LIST"
cmd "apt -y install python3 mariadb-client mylvmbackup mariadb-backup mariadb-server mariadb-plugin-cracklib-password-check mariadb-plugin-connect"
lRC=$(($lRC + $?))

cmd "apt -y install cracklib-runtime python3-cracklib tree telnet netcat-openbsd netcat libjemalloc2 libdbi-perl libdbd-mysql-perl rsync nmap lsof pigz git pwgen"
lRC=$(($lRC + $?))

cmd "apt -y install percona-toolkit mycli"
lRC=$(($lRC + $?))

[ -d "/opt/local" ] || cmd "mkdir -p /opt/local"

[ -d "/opt/local/MySQLTuner-perl" ] && cmd "rm -rf /opt/local/MySQLTuner-perl"

cd /opt/local
cmd "git clone https://github.com/major/MySQLTuner-perl.git"
lRC=$(($lRC + $?))

cmd "chmod 755 /opt/local/MySQLTuner-perl/mysqltuner.pl"

echo 'export PATH=$PATH:/opt/local/MySQLTuner-perl' > /etc/profile.d/mysqltuner.sh
chmod 755 /etc/profile.d/mysqltuner.sh


cmd " systemctl restart unattended-upgrades.service" " RESTART SOME SERVICES"
footer "END SCRIPT: $NAME"
exit $lRC