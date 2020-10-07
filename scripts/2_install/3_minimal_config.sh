#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
CONF_FILE="/etc/my.cnf.d/99_minimal_config.cnf"
server_id=$(hostname -s| perl -pe 's/.+?(\d+)/$1/')
mem_gb=$(free -g| grep Mem: | awk '{print $2}')
[ $mem_gb -eq 0 ] && mem_gb=1


banner "BEGIN SCRIPT: $_NAME"

cmd "rm -f $CONF_FILE"

info "SETUP $(basename $CONF_FILE) FILE INTO $(dirname $CONF_FILE)"

(
echo "# Minimal configuration - created $(date)"
python3 /opt/local/bin/mygenconf.py server_id=$server_id mysql_ram_gb=$mem_gb
) | tee -a $CONF_FILE

cmd "chmod 644 $CONF_FILE"

perl -i -pe 's/LimitNOFILE=\d+/LimitNOFILE=infinity/g' /usr/lib/systemd/system/mysqld.service
perl -i -pe 's/LimitNOFILE=\d+/LimitNOFILE=infinity/g' /usr/lib/systemd/system/mariadb.service

cmd "journalctl --rotate -u mariadb"
cmd "journalctl --vacuum-time=1s -u mariadb"
cmd "systemctl disable mariadb"
cmd "systemctl enable mariadb"
cmd "systemctl daemon-reload"
cmd "systemctl restart mariadb"

sleep 3s

cmd "netstat -ltnp"

ps -edf |grep [m]ysqld

cmd "ls -ls /var/lib/mysql"

cmd "journalctl -xe -o cat -u mariadb"

cmd "tail -n 15 /var/lib/mysql/mysqld.log"

footer "END SCRIPT: $NAME"
exit $lRC