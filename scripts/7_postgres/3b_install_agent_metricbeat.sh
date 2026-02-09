#!/bin/bash

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)
source /etc/os-release

lRC=0
VERSION=${1:-"13"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: ${_NAME}"


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
footer "END SCRIPT: ${_NAME}"
exit $lRC
