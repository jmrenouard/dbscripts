#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.8"}

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


footer "END SCRIPT: $NAME"
exit $lRC