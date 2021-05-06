#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

origin=https://raw.githubusercontent.com/jmrenouard/easymysql/master/mysql_functions.sh

banner "BEGIN SCRIPT: $_NAME"

cd /var/tmp

curl -O "$origin"
mv mysql_functions.sh easymysql.sh
chmod 755 easymysql.sh
mv easymysql.sh /etc/profile.d/

footer "BEGIN SCRIPT: $_NAME"