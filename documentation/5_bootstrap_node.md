# Standard Operation: Galera Cluster bootstrap

## Table of contents
- [Main document target](#main-document-target)
- [Scripted and remote update procedure](#scripted-and-remote-update-procedure)
- [Update Procedure example remotely](#update-procedure-example-remotely)

## Main document target

>  * Start  a 1st operationnal node
>  *  Start a consistent first node
>  * Galera Cluster initialisation
## Scripted and remote update procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv1 ../scripts/2_install/5_bootstrap_node.sh |
| 3 | Check return code | root | echo 0 (0) |

##  Update Procedure example remotely
```bash
# vssh_exec dbsrv1 ../scripts/2_install/5_bootstrap_node.sh
2021-05-27 15:47:53 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 5_bootstrap_node.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-27 15:47:53 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) START: BEGIN SCRIPT: INLINE SHELL
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO:  run as root@dbsrv1
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) RUNNING COMMAND: rm -f /etc/my.cnf.d/999_galera_settings.cnf
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-27 15:47:53 CEST(dbsrv1) INFO: [SUCCESS]  rm -f /etc/my.cnf.d/999_galera_settings.cnf  [SUCCESS]
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO: SETUP 999_galera_settings.cnf FILE INTO /etc/my.cnf.d
# Minimal Galera configuration - created Thu May 27 15:47:53 CEST 2021
[server]
binlog-format=ROW
default-storage-engine=innodb
innodb-autoinc-lock-mode=2
innodb-flush-log-at-trx-commit = 0

wsrep-on=on
wsrep-provider=/usr/lib64/galera-4/libgalera_smm.so

wsrep-slave-threads=4
wsrep-cluster-name=adistacluster
wsrep-node-name=dbsrv1
wsrep-node-address=192.168.33.191
wsrep-cluster-address=gcomm://192.168.33.191,192.168.33.192,192.168.33.193
#wsrep-cluster-address=gcomm://

wsrep-sst-method=mariabackup
wsrep-sst-auth=galera:kee2iesh1Ohk1puph8
#wsrep-notify-cmd=/opt/local/bin/table_wsrep_notif.sh
wsrep-notify-cmd=/opt/local/bin/file_wsrep_notif.sh

2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) RUNNING COMMAND: chmod 644 /etc/my.cnf.d/999_galera_settings.cnf
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-27 15:47:53 CEST(dbsrv1) INFO: [SUCCESS]  chmod 644 /etc/my.cnf.d/999_galera_settings.cnf  [SUCCESS]
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) RUNNING COMMAND: systemctl stop mariadb
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-27 15:47:53 CEST(dbsrv1) INFO: [SUCCESS]  systemctl stop mariadb  [SUCCESS]
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) RUNNING COMMAND: rm -f /var/lib/mysql//galera.cache /var/lib/mysql//grastate.dat /var/lib/mysql//gvwstate.dat
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-27 15:47:53 CEST(dbsrv1) INFO: [SUCCESS]  rm -f /var/lib/mysql//galera.cache /var/lib/mysql//grastate.dat /var/lib/mysql//gvwstate.dat  [SUCCESS]
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:53 CEST(dbsrv1) RUNNING COMMAND: /usr/bin/galera_new_cluster
2021-05-27 15:47:53 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:55 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-27 15:47:55 CEST(dbsrv1) INFO: [SUCCESS]  /usr/bin/galera_new_cluster  [SUCCESS]
2021-05-27 15:47:55 CEST(dbsrv1) -----------------------------------------------------------------------------
--------------
install soname 'wsrep_info'
--------------

*************************** 1. row ***************************
         NODE_INDEX: 0
        NODE_STATUS: synced
     CLUSTER_STATUS: primary
       CLUSTER_SIZE: 1
 CLUSTER_STATE_UUID: 234b2721-bef2-11eb-8575-a3e608f82678
CLUSTER_STATE_SEQNO: 1
    CLUSTER_CONF_ID: 1
   PROTOCOL_VERSION: 4
INDEX	UUID	NAME	ADDRESS
0	234a2515-bef2-11eb-907c-5229f2f88f2f	dbsrv1	AUTO
load pubkey "/root/.ssh/id_rsa": invalid format
Host key verification failed.
lost connection
load pubkey "/root/.ssh/id_rsa": invalid format
Host key verification failed.
lost connection
2021-05-27 15:47:55 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:55 CEST(dbsrv1) END: END SCRIPT: CentOS Linux ENDED SUCCESSFULLY
2021-05-27 15:47:55 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-27 15:47:56 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-27 15:47:56 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 5_bootstrap_node.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-27 15:47:56 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
# echo 0
0

```

