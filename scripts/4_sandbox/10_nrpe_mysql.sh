#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "NRPE & MySQL/MariaDB"
soft=check_mysql_health-2.2.2
cd /var/tmp
curl -O https://labs.consol.de/assets/downloads/nagios/$soft.tar.gz
tar xvzf $soft.tar.gz
cd $soft
./configure
make 
make install

cp plugins-scripts/check_mysql* /opt/local/bin
echo "CREATE OR REPLACE USER 'nrpe'@'localhost' IDENTIFIED BY 'nrpe';
grant usage,select on *.* to 'nrpe'@'localhost';" | mysql -v

yum -y install nrpe nagios-plugins-nrpe nagios-plugins-disk.x86_64 nagios-plugins-tcp 
yum -y install nagios-plugins-load.x86_64  nagios-plugins-ntp.x86_64 nagios-plugins-procs nagios-plugins-logs

modes="connection-time
uptime
threads-connected
threadcache-hitrate
threads-created
threads-running 
threads-cached   
connects-aborted 
clients-aborted
bufferpool-hitrate
bufferpool-wait-free
log-waits
tablecache-hitrate 
table-lock-contention    
index-usage                      
tmp-disk-tables                        
table-fragmentation                     
open-files                              
slow-queries                            
long-running-procs"

other_modes="slave-lag           
slave-io-running    
slave-sql-running   
qcache-hitrate      
qcache-lowmem-prunes
keycache-hitrate
cluster-ndbd-running  
sql"                               

set -x
set +x
chmod 755 ./plugins-scripts/check_mysql_health  

echo "command[disk]=/usr/lib64/nagios/plugins/check_disk -w80 -c95
command[tcp_3306]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p3306
command[tcp_5666]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p5666
command[load]=/usr/lib64/nagios/plugins/check_load -w1,1,1 -c 3,3,3
command[mysql-proc]=/usr/lib64/nagios/plugins/check_procs -a 'mariadb' -c 1 -w 1
command[nrpe-proc]=/usr/lib64/nagios/plugins/check_procs -a 'nrpe' -c 1 -w 1
command[mysql-error-log]=/usr/lib64/nagios/plugins/check_log -F /var/log/mysql/mysqld.log -O /tmp/mysql-err.log -q ERROR -w 1
command[mysql-warn-log]=/usr/lib64/nagios/plugins/check_log -F /var/log/mysql/mysqld.log -O /tmp/mysql-warn.log -q Warning -w 1
">/etc/nrpe.d/linux.cfg

echo "">/etc/nrpe.d/mysql.cfg 

for mode in $modes; do
    ./plugins-scripts/check_mysql_health --mode $mode --user nrpe --password nrpe
    echo "command[mysql-$mode]=/opt/local/bin/check_mysql_health  --mode $mode --user nrpe --password nrpe">>/etc/nrpe.d/mysql.cfg 
done
systemctl restart nrpe 
echo "----------------------------------------------------"
for mode in $modes; do
    echo "CHECK NRPE: mysql-$mode"
    /usr/lib64/nagios/plugins/check_nrpe -H127.0.0.1 -c mysql-$mode
done
echo "----------------------------------------------------"
for mode in disk tcp_3306 tcp_5666 load mysql-proc nrpe-proc mysql-error-log mysql-warn-log; do
    echo "CHECK NRPE: $mode"
    /usr/lib64/nagios/plugins/check_nrpe -H127.0.0.1 -c $mode
done
echo "----------------------------------------------------"

footer "NRPE & MySQL/MariaDB"