#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

source /etc/os-release

lRC=0
VERSION=${1:-"10.11"}

##title_en: Centos MariaDB 10.11 server installation
##title_fr: Installation du serveur MariaDB 10.11 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
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

curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash

if [ "$force" = "1" ]; then
	cmd "yum -y remove mysql-server mariadb-server"
	lRC=$(($lRC + $?))
fi

cmd "yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"
lRC=$(($lRC + $?))

cmd "yum -y install MariaDB-server galera-4 MariaDB-client MariaDB-shared MariaDB-backup MariaDB-common"

cmd "yum -y install pv python3 mylvmbackup MariaDB-cracklib-password-check MariaDB-connect-engine"
lRC=$(($lRC + $?))

cmd "yum -y install cracklib cracklib-dicts tree socat sysbench jemalloc rsync nmap lsof net-tools perl-DBI nc mariadb-server-utils pigz perl-DBD-MySQL git pwgen"
lRC=$(($lRC + $?))

cmd "yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
lRC=$(($lRC + $?))
cmd "yum -y install percona-toolkit"
lRC=$(($lRC + $?))
cmd "yum -y install https://github.com/mydumper/mydumper/releases/download/v0.12.5-3/mydumper-0.12.5-3.el7.x86_64.rpm"
#cmd "yum -y install https://github.com/mydumper/mydumper/releases/download/v0.11.3-3/mydumper-0.11.3-3.el${VERSION_ID}.x86_64.rpm"
lRC=$(($lRC + $?))

#cmd "yum -y install https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-24.fc34.noarch.rpm"
#lRC=$(($lRC + $?))

[ -d "/opt/local" ] || cmd "mkdir -p /opt/local"

if [ -d "/opt/local/MySQLTuner-perl" ]; then
	cd /opt/local/MySQLTuner-perl
	cmd "git pull"
else
	cd /opt/local
	cmd "git clone https://github.com/major/MySQLTuner-perl.git"
fi
lRC=$(($lRC + $?))

cmd "chmod 755 /opt/local/MySQLTuner-perl/mysqltuner.pl"

echo 'export PATH=$PATH:/opt/local/MySQLTuner-perl' > /etc/profile.d/mysqltuner.sh
chmod 755 /etc/profile.d/mysqltuner.sh

footer "END SCRIPT: $NAME"
exit $lRC