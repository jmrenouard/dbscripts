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

cmd "rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch"
lRC=$(($lRC + $?))

echo "[elasticstack]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/elacticsearch.repo

cmd "dnf -y update"
lRC=$(($lRC + $?))

cmd "dnf -y install filebeat metricbeat"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC
