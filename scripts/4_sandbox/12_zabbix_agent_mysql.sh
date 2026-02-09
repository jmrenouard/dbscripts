#!/bin/bash

source /etc/os-release

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

lRC=0
zabbix_password="Jiegohkoh6aePh6phu"

banner "BEGIN SCRIPT: ${_NAME}"

(
	cat <<'EndOfScript'
UserParameter=mysql.size[*],echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[$
UserParameter=mysql.ping,HOME=/etc/zabbix mysqladmin ping | grep -c alive 

UserParameter=mysql.uptime,HOME=/etc/zabbix mysqladmin status | cut -f2 -d ":" | cut -f1 -d "T" | tr -d " "
UserParameter=mysql.threads,HOME=/etc/zabbix mysqladmin status | cut -f3 -d ":" | cut -f1 -d "Q" | tr -d " "
UserParameter=mysql.questions,HOME=/etc/zabbix mysqladmin status | cut -f4 -d ":"|cut -f1 -d "S" | tr -d " "
UserParameter=mysql.slowqueries,HOME=/etc/zabbix mysqladmin status | cut -f5 -d ":" | cut -f1 -d "O" | tr -d " "
UserParameter=mysql.qps,HOME=/etc/zabbix mysqladmin status | cut -f9 -d ":" | tr -d " "
UserParameter=mysql.version,mysql -V
EndOfScript

) | tee /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf

cmd "chmod 755 /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf"

cmd "mkdir -p /var/lib/zabbix"
cmd "chown zabbix. /var/lib/zabbix"


echo "[mysql]
user=zabbix_admin
password=$zabbix_password
[mysqladmin]
user=zabbix_admin
password=$zabbix_password" | tee /var/lib/zabbix/.my.cnf
cmd "chmod 600 /var/lib/zabbix/.my.cnf"
cmd "chown zabbix. /var/lib/zabbix/.my.cnf"

echo "DROP USER IF EXISTS 'zabbix_admin'@'localhost';
create user 'zabbix_admin'@'localhost' IDENTIFIED BY '$zabbix_password';
GRANT ALL ON *.* TO 'zabbix_admin'@'localhost' IDENTIFIED BY '$zabbix_password';
DROP USER IF EXISTS 'zabbix_admin'@'%';
create user 'zabbix_admin'@'%' IDENTIFIED BY '$zabbix_password';
GRANt ALL ON *.* TO 'zabbix_admin'@'%' IDENTIFIED BY '$zabbix_password';
FLUSH PRIVILEGES;" | mysql -fv

sudo -u zabbix mysqladmin status

cmd "systemctl restart zabbix-agent"


footer "END SCRIPT: ${_NAME}"
exit $lRC