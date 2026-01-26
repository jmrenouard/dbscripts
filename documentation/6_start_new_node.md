# Standard Operation: Adding a new member into a galera Cluster

## Table of contents
- [Main document target](#main-document-target)
- [Scripted and remote updates procedure](#scripted-and-remote-updates-procedure)
- [Update Procedure example remotely](#update-procedure-example-remotely)

## Main document target

>  * Start a other operationnal node
>  *  Start a consistent new node
>  * Adding Galera Cluster member
## Scripted and remote updates procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv2 ../scripts/2_install/6_start_new_node.sh |
| 3 | Check return code | root | echo 0 (0) |

##  Update Procedure example remotely
```bash
# vssh_exec dbsrv2 ../scripts/2_install/6_start_new_node.sh
2021-05-27 15:53:13 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 6_start_new_node.sh ON dbsrv2(192.168.33.192) SERVER
2021-05-27 15:53:13 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) START: BEGIN SCRIPT: INLINE SHELL
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) INFO:  run as root@dbsrv2
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) RUNNING COMMAND: rm -f /etc/my.cnf.d/999_galera_settings.cnf
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) INFO: RETURN CODE: 0
2021-05-27 15:53:13 CEST(dbsrv2) INFO: [SUCCESS]  rm -f /etc/my.cnf.d/999_galera_settings.cnf  [SUCCESS]
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) INFO: SETUP 999_galera_settings.cnf FILE INTO /etc/my.cnf.d
# Minimal Galera configuration - created Thu May 27 15:53:13 CEST 2021
[server]
default-storage-engine=innodb

binlog-format=ROW
sync-binlog = 0
expire-logs-days=3

innodb-defragment=1
innodb-autoinc-lock-mode=2
innodb-flush-log-at-trx-commit = 2

wsrep-on=on
wsrep-provider=/usr/lib64/galera-4/libgalera_smm.so
wsrep-slave-threads=4
#wsrep-provider-options='gcache.size=512M;gcache.page_size=512M'

#wsrep_provider_options='cert.log_conflicts=yes';
#wsrep_log_conflicts=ON

#wsrep_provider_options='gcs.fc_mimit=1024';

wsrep-cluster-name=adistacluster
wsrep-node-name=dbsrv2
wsrep-node-address=192.168.33.192
wsrep-cluster-address=gcomm://192.168.33.191,192.168.33.192,192.168.33.193
#wsrep-cluster-address=gcomm://

wsrep-sst-method=mariabackup
wsrep-sst-auth=galera:ohGh7boh7eeg6shuph
#wsrep-notify-cmd=/opt/local/bin/table_wsrep_notif.sh
wsrep-notify-cmd=/opt/local/bin/file_wsrep_notif.sh

2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) RUNNING COMMAND: chmod 644 /etc/my.cnf.d/999_galera_settings.cnf
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) INFO: RETURN CODE: 0
2021-05-27 15:53:13 CEST(dbsrv2) INFO: [SUCCESS]  chmod 644 /etc/my.cnf.d/999_galera_settings.cnf  [SUCCESS]
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) RUNNING COMMAND: rm -f /var/lib/mysql//galera.cache /var/lib/mysql//grastate.dat /var/lib/mysql//gvwstate.dat
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) INFO: RETURN CODE: 0
2021-05-27 15:53:13 CEST(dbsrv2) INFO: [SUCCESS]  rm -f /var/lib/mysql//galera.cache /var/lib/mysql//grastate.dat /var/lib/mysql//gvwstate.dat  [SUCCESS]
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:13 CEST(dbsrv2) RUNNING COMMAND: systemctl restart mariadb
2021-05-27 15:53:13 CEST(dbsrv2) -----------------------------------------------------------------------------
Job for mariadb.service failed because a fatal signal was delivered to the control process.
See "systemctl status mariadb.service" and "journalctl -xe" for details.
2021-05-27 15:53:27 CEST(dbsrv2) INFO: RETURN CODE: 1
2021-05-27 15:53:27 CEST(dbsrv2) ERROR: systemctl restart mariadb
2021-05-27 15:53:27 CEST(dbsrv2) -----------------------------------------------------------------------------
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)
2021-05-27 15:53:27 CEST(dbsrv2) MEMBERS IN GALERA
2021-05-27 15:53:27 CEST(dbsrv2) _____________________________________________________________________________
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)
2021-05-27 15:53:27 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:27 CEST(dbsrv2) END: END SCRIPT: CentOS Linux ENDED SUCCESSFULLY
2021-05-27 15:53:27 CEST(dbsrv2) -----------------------------------------------------------------------------
2021-05-27 15:53:28 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-27 15:53:28 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 6_start_new_node.sh ON dbsrv2(192.168.33.192) SERVER ENDED SUCCESSFULLY
2021-05-27 15:53:28 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
# echo 0
0

```

