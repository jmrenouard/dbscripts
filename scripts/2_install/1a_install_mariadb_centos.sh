#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.5"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles

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

if [ "$force" = "1" ]; then
	cmd "yum -y remove mysql-server mariadb-server"
	lRC=$(($lRC + $?))
fi

cmd "yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm"
lRC=$(($lRC + $?))

cmd "yum -y install python3 MariaDB-server MariaDB-backup MariaDB-client MariaDB-compat MariaDB-cracklib-password-check MariaDB-connect-engine"
lRC=$(($lRC + $?))

cmd "yum -y install cracklib cracklib-dicts tree socat jemalloc rsync nmap lsof perl-DBI nc mariadb-server-utils pigz perl-DBD-MySQL git pwgen"
lRC=$(($lRC + $?))

cmd "yum -y install https://repo.percona.com/yum/release/latest/RPMS/x86_64/percona-toolkit-3.2.1-1.el6.x86_64.rpm"
ln -sf lRC=$(($lRC + $?))

#cmd "pip3 install mycli"
#lRC=$(($lRC + $?))

cmd "yum -y install https://github.com/maxbube/mydumper/releases/download/v0.10.5/mydumper-0.10.5-1.el${VERSION_ID}.x86_64.rpm"
lRC=$(($lRC + $?))

cmd "yum -y install https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-24.fc34.noarch.rpm"
lRC=$(($lRC + $?))

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

cmd "yum -y install perl-App-cpanminus"
#cmd "cpanm MySQL::Diff"
footer "END SCRIPT: $NAME"
exit $lRC