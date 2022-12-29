#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"10.8"}

banner "BEGIN SCRIPT: $_NAME"


find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

#if [ "$VERSION_CODENAME" = "groovy" ];then
cmd "apt-get install software-properties-common" "ADDING SOFTWARE PROPERTIES"
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository -y "deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/$VERSION/ubuntu $VERSION_CODENAME main"
##fi
cmd "apt -y update" "UPDATE PACKAGE LIST"
cmd "apt -y install python3 mariadb-client mylvmbackup sysbench mycli mariadb-backup socat telnet rsync tree nmap lsof netcat pigz git pwgen"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC