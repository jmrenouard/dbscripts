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

footer "END SCRIPT: $NAME"
exit $lRC