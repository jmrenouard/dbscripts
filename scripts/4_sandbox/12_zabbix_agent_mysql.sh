#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "Zabbix MySQL Agent"


(
	cat <<'EndOfScript'
# For all the following commands HOME should be set to the directory that has .my.cnf file with password information.
#
# Flexible parameter to grab global variables. On the frontend side, use keys like mysql.status[Com_insert].
# Key syntax is mysql.status[variable].
UserParameter=mysql.status[*],echo "show global status where Variable_name='$1';" | HOME=/etc/zabbix mysql -N | awk '{print $$2}' # My line
#
# Flexible parameter to determine database or table size. On the frontend side, use keys like mysql.size[zabbix,history,data].
# Key syntax is mysql.size[<database>,<table>,<type>].
# Database may be a database name or "all". Default is "all".
# Table may be a table name or "all". Default is "all".
# Type may be "data", "index", "free" or "both". Both is a sum of data and index. Default is "both".
# Database is mandatory if a table is specified. Type may be specified always.
# Returns value in bytes.
# 'sum' on data_length or index_length alone needed when we are getting this information for whole database instead of a single table
UserParameter=mysql.size[*],echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[$
#
#Default below
UserParameter=mysql.ping,HOME=/etc/zabbix mysqladmin ping | grep -c alive 
#
#My line
UserParameter=mysql.uptime,HOME=/etc/zabbix mysqladmin status | cut -f2 -d ":" | cut -f1 -d "T" | tr -d " "
UserParameter=mysql.threads,HOME=/etc/zabbix mysqladmin status | cut -f3 -d ":" | cut -f1 -d "Q" | tr -d " "
UserParameter=mysql.questions,HOME=/etc/zabbix mysqladmin status | cut -f4 -d ":"|cut -f1 -d "S" | tr -d " "
UserParameter=mysql.slowqueries,HOME=/etc/zabbix mysqladmin status | cut -f5 -d ":" | cut -f1 -d "O" | tr -d " "
UserParameter=mysql.qps,HOME=/etc/zabbix mysqladmin status | cut -f9 -d ":" | tr -d " "
UserParameter=mysql.version,mysql -V
EndOfScript

) | tee /etc/zabbix/zabbix_agentd.conf.d/userparameter_mysql.conf

chmod 755 /etc/zabbix/zabbix_agentd.conf.d/userparameter_mysql.conf

(
	cat <<'EndOfScript'
[mysql]
user=zabbix_admin
password=Password
[mysqladmin]
user=zabbix_admin
password=Password
EndOfScript

) | tee /home/zabbix/.my.cnf
chmod 600 /home/zabbix/.my.cnf

echo "create user 'zabbix_admin'@'localhost' IDENTIFIED BY 'Password';
GRANT USAGE ON *.* TO 'zabbix_admin'@'localhost' IDENTIFIED BY 'Password';
FLUSH PRIVILEGES;" | mysql -fv

cmd "systemctl restart zabbix-agent"


footer "Zabbix Agent"
exit $lRC