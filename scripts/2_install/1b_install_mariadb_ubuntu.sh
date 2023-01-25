#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.6"}

banner "BEGIN SCRIPT: $_NAME"

find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash

cmd "apt -y install pv python3 mariadb-client mylvmbackup mariadb-backup mariadb-server mariadb-plugin-cracklib-password-check mariadb-plugin-connect galera-arbitrator-4"
lRC=$(($lRC + $?))

cmd "apt -y install cracklib-runtime python3-cracklib sysbench tree telnet netcat-openbsd netcat libjemalloc2 libdbi-perl libdbd-mysql-perl rsync nmap lsof pigz git pwgen"
lRC=$(($lRC + $?))

cmd "apt -y install percona-toolkit mycli net-tools"
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