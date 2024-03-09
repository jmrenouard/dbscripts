#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

source /etc/os-release

lRC=0
VERSION=${1:-"10.11"}
##title_en: Ubuntu MariaDB 10.11 server installation
##title_fr: Installation du serveur MariaDB 10.11 sur OS Ubuntu  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles

banner "BEGIN SCRIPT: $_NAME"

find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

#curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup > ./mariadb_repo_setup
#bash ./mariadb_repo_setup --mariadb-server-version="mariadb-${VERSION}"
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-${VERSION}" 
cmd "apt -y install pv python3 mariadb-client mylvmbackup mariadb-backup mariadb-server mariadb-plugin-cracklib-password-check mariadb-plugin-connect galera-arbitrator-4"
lRC=$(($lRC + $?))

cmd "apt -y install cracklib-runtime python3-cracklib sysbench tree telnet netcat-openbsd netcat libjemalloc2 libdbi-perl libdbd-mysql-perl rsync nmap lsof pigz git pwgen"
lRC=$(($lRC + $?))

cmd "apt -y install mycli net-tools"
lRC=$(($lRC + $?))

wget https://downloads.percona.com/downloads/percona-toolkit/3.5.7/binary/debian/jammy/x86_64/percona-toolkit_3.5.7-1.jammy_amd64.deb
cmd "dpkg -i percona-toolkit_3.5.7-1.jammy_amd64.deb"
lRC=$(($lRC + $?))

cmd "apt -y install nagios-nrpe-server nagios-nrpe-plugin centreon-plugins monitoring-plugins monitoring-plugins-contrib nagios-snmp-plugins"
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