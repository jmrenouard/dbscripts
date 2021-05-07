#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
VERSION=10.5

banner "BEGIN SCRIPT: $_NAME"

cmd 'rm -f /etc/yum.repos.d/mariadb_*.repo'

cmd "yum -y remove mysql-server mariadb-server MariaDB-backup MariaDB-client MariaDB-compat socat jemalloc  nmap pwgen lsof perl-DBI nc mariadb-server-utils pigz perl-DBD-MySQL perl-DBI percona-toolkit mysqlreport"
lRC=$(($lRC + $?))

[ -d "/opt/local/MySQLTuner-perl" ] && cmd "rm -rf /opt/local/MySQLTuner-perl"


cmd "rm -f /etc/profile.d/mysqltuner.sh"

footer "END SCRIPT: $NAME"
exit $lRC