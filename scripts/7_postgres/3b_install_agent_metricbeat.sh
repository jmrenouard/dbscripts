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


sed -i -e '/host:/d' -e '/hosts:/d' -e '/username:/d' -e '/password:/d' /etc/metricbeat/metricbeat.yml

perl -i -pe 's/".*:9200"/"139.162.226.249:9200"/g' /etc/metricbeat/metricbeat.yml

perl -i -pe 's/(setup.kibana:)/$1
    host: "139.162.226.249:5601"
    username: "elastic"
    password: "elastic"
    /g' /etc/metricbeat/metricbeat.yml

perl -i -pe 's/(output.elasticsearch:)/$1
    hosts: [ "139.162.226.249:9200" ]
    username: "elastic"
    password: "elastic"
    /g' /etc/metricbeat/metricbeat.yml

cmd "metricbeat modules list"

cmd "metricbeat modules enable postgresql"
lRC=$(($lRC + $?))

echo "# Module: postgresql
# Docs: https://www.elastic.co/guide/en/beats/metricbeat/7.x/metricbeat-module-postgresql.html

- module: postgresql
  metricsets:
    - database
    - bgwriter
    - activity

  period: 5s
  hosts: ["postgres://localhost:5432?sslmode=disable"]
  username: postgres
  password: postgres
" > /etc/metricbeat/modules.d/postgresql.yml


cmd "metricbeat test config -e"
lRC=$(($lRC + $?))

cmd "metricbeat test modules postgresql -e"
lRC=$(($lRC + $?))

cmd "metricbeat setup -e"

cmd "systemctl restart metricbeat"
lRC=$(($lRC + $?))

cmd "systemctl enable metricbeat"
lRC=$(($lRC + $?))
footer "END SCRIPT: $NAME"
exit $lRC
