#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"


lRC=0
VERSION=10.5

banner "BEGIN SCRIPT: $_NAME"

find /etc/apt/sources.list.d -type f -iname '*mariadb*.list' -exec rm -f {} \;

cmd "apt -y update" "UPDATE PACKAGE LIST"

cmd "apt -y remove mariadb-client mariadb-backup mariadb-server mariadb-plugin-cracklib-password-check mariadb-plugin-connect socat libjemalloc2 nmap pwgen lsof pigz percona-toolkit"
lRC=$(($lRC + $?))

[ -d "/opt/local/MySQLTuner-perl" ] && cmd "rm -rf /opt/local/MySQLTuner-perl"


cmd "rm -f /etc/profile.d/mysqltuner.sh"

footer "END SCRIPT: $NAME"
exit $lRC