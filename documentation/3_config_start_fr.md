# Opération Standard : Cionfiguration du serveur MariaDB 10.5 basée sur la RAM et CPU

## Table des matières
- [Objectifs du document](#objectifs-du-document)
- [Procédure scriptées à distance via SSH](#procédure-scriptées-à-distance-via-ssh)
- [Exemple de procédure à distance par script](#exemple-de-procédure-à-distance-par-script)

## Objectifs du document

>  * Creation du fichier de configuration
>  * Paramétrage du service mariadb
>  * Nettoyage des fichiers de logs
>  * Démarrage du service
>  * vérification de l etat du service
## Procédure scriptées à distance via SSH
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv1 ../scripts/2_install/3_config_start.sh |
| 3 | Vérifier le code retour  | root | echo 0 (0) |

##  Exemple de procédure à distance par script
```bash
# vssh_exec dbsrv1 ../scripts/2_install/3_config_start.sh
2021-05-26 22:25:30 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 3_config_start.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-26 22:25:30 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-26 22:25:30 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:30 CEST(dbsrv1) START: BEGIN SCRIPT: INLINE SHELL
2021-05-26 22:25:30 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:30 CEST(dbsrv1) INFO:  run as root@dbsrv1
2021-05-26 22:25:30 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:30 CEST(dbsrv1) RUNNING COMMAND: rm -f /etc/my.cnf.d/99_minimal_config.cnf
2021-05-26 22:25:30 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:30 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:30 CEST(dbsrv1) INFO: [SUCCESS]  rm -f /etc/my.cnf.d/99_minimal_config.cnf  [SUCCESS]
2021-05-26 22:25:30 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:30 CEST(dbsrv1) INFO: SETUP 99_minimal_config.cnf FILE INTO /etc/my.cnf.d
# Minimal configuration - created Wed May 26 22:25:30 CEST 2021

[mysqld]
# GENERAL #
user                           = mysql
default-storage-engine         = InnoDB
socket                         = /run/mysqld/mysqld.sock
pid-file                       = mysqld.pid
# MyISAM #
# key-buffer-size                = 32M
# myisam-recover                 = FORCE,BACKUP

# SAFETY #
max-allowed-packet             = 16M
max-connect-errors             = 1000000
skip-name-resolve
sql-mode                       = NO_ENGINE_SUBSTITUTION,NO_AUTO_CREATE_USER
sysdate-is-now                 = 1
innodb-strict-mode             = 1

# DATA STORAGE #
datadir                        = /var/lib/mysql

# SERVER ID #
server-id                      = 1
report-host                    = server-1
# BINARY LOGGING #
log-bin                        = mysqld-bin

# CACHES AND LIMITS #
max-connections                = 100
tmp-table-size                 = 32M
max-heap-table-size            = 32M
query-cache-type               = 0
query-cache-size               = 0
thread-cache-size              = 50
open-files-limit               = 16000

table-definition-cache         = 400
table-open-cache               = 128
# INNODB #
innodb-flush-method            = O_DIRECT
innodb-defragment			   = 1
# DePRECATED IN MARIADB 10.5
# innodb-log-files-in-group      = 2

innodb-log-file-size           = 96M
innodb-flush-log-at-trx-commit = 1
innodb-file-per-table          = 1
innodb-buffer-pool-size        = 768M
innodb_buffer_pool_chunk_size  = 201326592
# LOGGING #
log-error                      = /var/log/mysql/mysqld.log
slow-query-log                 = 1
slow-query-log-file            = /var/log/mysql/mysqld.log
log-queries-not-using-indexes  = ON
long_query_time                = 30
bind_address                   = 0.0.0.0
port                           = 3306
performance_schema=ON
performance_schema_max_cond_classes     =80
performance_schema_max_file_classes     =50
performance_schema_max_mutex_classes    =200
performance_schema_max_rwlock_classes   =40
performance_schema_max_socket_classes   =10
performance_schema_max_stage_classes    =150
performance_schema_max_statement_classes=168
performance_schema_max_thread_classes   =50

performance_schema_accounts_size=100
performance_schema_hosts_size   =100
performance_schema_users_size   =100
performance_schema_events_stages_history_long_size    =1000
performance_schema_events_stages_history_size         =10
performance_schema_events_statements_history_long_size=1000
performance_schema_events_statements_history_size     =10
performance_schema_events_waits_history_long_size     =10000
performance_schema_events_waits_history_size          =10

performance_schema_max_cond_instances   =1258
performance_schema_max_file_handles     =32768
performance_schema_max_file_instances   =6250
performance_schema_max_mutex_instances  =5133
performance_schema_max_rwlock_instances =2765
performance_schema_max_table_handles    =366
performance_schema_max_table_instances  =587
performance_schema_max_socket_instances =230
performance_schema_max_thread_instances =288
performance_schema_setup_actors_size =100
performance_schema_setup_objects_size=100

performance_schema_session_connect_attrs_size=512
performance_schema_digests_size              =200

2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: chmod 644 /etc/my.cnf.d/99_minimal_config.cnf
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:31 CEST(dbsrv1) INFO: [SUCCESS]  chmod 644 /etc/my.cnf.d/99_minimal_config.cnf  [SUCCESS]
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: journalctl --rotate -u mariadb
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:31 CEST(dbsrv1) INFO: [SUCCESS]  journalctl --rotate -u mariadb  [SUCCESS]
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: systemctl disable mariadb
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:31 CEST(dbsrv1) INFO: [SUCCESS]  systemctl disable mariadb  [SUCCESS]
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: systemctl unmask mariadb
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:31 CEST(dbsrv1) INFO: [SUCCESS]  systemctl unmask mariadb  [SUCCESS]
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: systemctl enable mariadb
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
2021-05-26 22:25:31 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:31 CEST(dbsrv1) INFO: [SUCCESS]  systemctl enable mariadb  [SUCCESS]
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:31 CEST(dbsrv1) RUNNING COMMAND: systemctl daemon-reload
2021-05-26 22:25:31 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:32 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:32 CEST(dbsrv1) INFO: [SUCCESS]  systemctl daemon-reload  [SUCCESS]
2021-05-26 22:25:32 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:32 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:32 CEST(dbsrv1) RUNNING COMMAND: systemctl restart mariadb
2021-05-26 22:25:32 CEST(dbsrv1) -----------------------------------------------------------------------------
Job for mariadb.service failed because the control process exited with error code.
See "systemctl status mariadb.service" and "journalctl -xe" for details.
2021-05-26 22:25:32 CEST(dbsrv1) INFO: RETURN CODE: 1
2021-05-26 22:25:32 CEST(dbsrv1) ERROR: systemctl restart mariadb
2021-05-26 22:25:32 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:35 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:35 CEST(dbsrv1) RUNNING COMMAND: netstat -ltnp
2021-05-26 22:25:35 CEST(dbsrv1) -----------------------------------------------------------------------------
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      637/sshd            
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      1/systemd           
tcp6       0      0 :::22                   :::*                    LISTEN      637/sshd            
tcp6       0      0 :::111                  :::*                    LISTEN      1/systemd           
2021-05-26 22:25:36 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:36 CEST(dbsrv1) INFO: [SUCCESS]  netstat -ltnp  [SUCCESS]
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) RUNNING COMMAND: netstat -lxnp
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
Active UNIX domain sockets (only servers)
Proto RefCnt Flags       Type       State         I-Node   PID/Program name     Path
unix  2      [ ACC ]     STREAM     LISTENING     18176    1/systemd            /run/rpcbind.sock
unix  2      [ ACC ]     SEQPACKET  LISTENING     18204    1/systemd            /run/systemd/coredump
unix  2      [ ACC ]     STREAM     LISTENING     11319    1/systemd            /run/systemd/journal/stdout
unix  2      [ ACC ]     STREAM     LISTENING     22186    653/sssd_nss         /var/lib/sss/pipes/nss
unix  2      [ ACC ]     STREAM     LISTENING     22083    642/gssproxy         /run/gssproxy.sock
unix  2      [ ACC ]     STREAM     LISTENING     20549    1/systemd            /var/run/.heim_org.h5l.kcm-socket
unix  2      [ ACC ]     STREAM     LISTENING     20551    1/systemd            /run/dbus/system_bus_socket
unix  2      [ ACC ]     STREAM     LISTENING     21627    607/sssd             /var/lib/sss/pipes/private/sbus-monitor
unix  2      [ ACC ]     STREAM     LISTENING     22082    642/gssproxy         /var/lib/gssproxy/default.sock
unix  2      [ ACC ]     STREAM     LISTENING     22144    640/sssd_be          /var/lib/sss/pipes/private/sbus-dp_implicit_files.640
unix  2      [ ACC ]     STREAM     LISTENING     17869    1/systemd            /run/systemd/private
unix  2      [ ACC ]     STREAM     LISTENING     167631   22156/systemd        /run/user/0/systemd/private
unix  2      [ ACC ]     STREAM     LISTENING     167640   22156/systemd        /run/user/0/bus
unix  2      [ ACC ]     SEQPACKET  LISTENING     17884    1/systemd            /run/udev/control
2021-05-26 22:25:36 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:36 CEST(dbsrv1) INFO: [SUCCESS]  netstat -lxnp  [SUCCESS]
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) RUNNING COMMAND: ps -edf |grep [m]ysqld
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
error: garbage option

Usage:
 ps [options]

 Try 'ps --help <simple|list|output|threads|misc|all>'
  or 'ps --help <s|l|o|t|m|a>'
 for additional help text.

For more details see ps(1).
2021-05-26 22:25:36 CEST(dbsrv1) INFO: RETURN CODE: 1
2021-05-26 22:25:36 CEST(dbsrv1) ERROR: ps -edf |grep [m]ysqld
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) RUNNING COMMAND: ls -ls /var/lib/mysql
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
total 110636
   24 -rw-rw----. 1 mysql mysql     24576 May 26 22:25 aria_log.00000001
    4 -rw-rw----. 1 mysql mysql        52 May 26 22:25 aria_log_control
    4 -rw-rw-rw-. 1 mysql mysql       976 May 26 22:25 ib_buffer_pool
12288 -rw-rw----. 1 mysql mysql  12582912 May 26 22:25 ibdata1
98304 -rw-rw----. 1 mysql mysql 100663296 May 26 22:25 ib_logfile0
    4 drwx------. 2 mysql mysql      4096 May 26 17:45 mysql
    4 -rw-rw----. 1 mysql mysql       352 May 26 22:25 mysqld-bin.000001
    4 -rw-rw----. 1 mysql mysql        20 May 26 22:25 mysqld-bin.index
    0 -rw-rw----. 1 mysql mysql         0 May 26 22:25 mysqld-bin.state
    0 drwx------. 2 mysql mysql        20 May 26 17:45 performance_schema
    0 drwx------. 2 mysql mysql        20 May 26 17:45 test
2021-05-26 22:25:36 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:36 CEST(dbsrv1) INFO: [SUCCESS]  ls -ls /var/lib/mysql  [SUCCESS]
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:36 CEST(dbsrv1) RUNNING COMMAND: journalctl -xe -o cat -u mariadb
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
Starting MariaDB 10.5.10 database server...
2021-05-26 22:25:32 0 [Note] /usr/sbin/mariadbd (mysqld 10.5.10-MariaDB-log) starting as process 22799 ...
/usr/sbin/mariadbd: Can't create file '/var/log/mysql/mysqld.log' (errno: 2 "No such file or directory")
2021-05-26 22:25:32 0 [Note] CONNECT: Version 1.07.0002 March 22, 2021
2021-05-26 22:25:32 0 [Note] InnoDB: Uses event mutexes
2021-05-26 22:25:32 0 [Note] InnoDB: Compressed tables use zlib 1.2.11
2021-05-26 22:25:32 0 [Note] InnoDB: Number of pools: 1
2021-05-26 22:25:32 0 [Note] InnoDB: Using SSE4.2 crc32 instructions
2021-05-26 22:25:32 0 [Note] mariadbd: O_TMPFILE is not supported on /tmp (disabling future attempts)
2021-05-26 22:25:32 0 [Note] InnoDB: Using Linux native AIO
2021-05-26 22:25:32 0 [Note] InnoDB: Initializing buffer pool, total size = 805306368, chunk size = 201326592
2021-05-26 22:25:32 0 [Note] InnoDB: Completed initialization of buffer pool
2021-05-26 22:25:32 0 [Note] InnoDB: 128 rollback segments are active.
2021-05-26 22:25:32 0 [Note] InnoDB: Creating shared tablespace for temporary tables
2021-05-26 22:25:32 0 [Note] InnoDB: Setting file './ibtmp1' size to 12 MB. Physically writing the file full; Please wait ...
2021-05-26 22:25:32 0 [Note] InnoDB: File './ibtmp1' size is now 12 MB.
2021-05-26 22:25:32 0 [Note] InnoDB: 10.5.10 started; log sequence number 45106; transaction id 20
2021-05-26 22:25:32 0 [Note] Plugin 'FEEDBACK' is disabled.
2021-05-26 22:25:32 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
2021-05-26 22:25:32 0 [ERROR] mariadbd: File '/var/log/mysql/mysqld.log' not found (Errcode: 2 "No such file or directory")
2021-05-26 22:25:32 0 [ERROR] Could not use /var/log/mysql/mysqld.log for logging (error 2). Turning logging off for the whole duration of the MariaDB server process. To turn it on again: fix the cause, shutdown the MariaDB server and restart it.
2021-05-26 22:25:32 0 [Note] Server socket created on IP: '0.0.0.0'.
2021-05-26 22:25:32 0 [ERROR] Can't start server : Bind on unix socket: No such file or directory
2021-05-26 22:25:32 0 [ERROR] Do you already have another mysqld server running on socket: /run/mysqld/mysqld.sock ?
2021-05-26 22:25:32 0 [ERROR] Aborting
mariadb.service: Main process exited, code=exited, status=1/FAILURE
mariadb.service: Failed with result 'exit-code'.
Failed to start MariaDB 10.5.10 database server.
2021-05-26 22:25:36 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:36 CEST(dbsrv1) INFO: [SUCCESS]  journalctl -xe -o cat -u mariadb  [SUCCESS]
2021-05-26 22:25:36 CEST(dbsrv1) -----------------------------------------------------------------------------
failed
3
2021-05-26 22:25:39 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:39 CEST(dbsrv1) RUNNING COMMAND: git clone https://github.com/FromDual/mariadb-sys.git
2021-05-26 22:25:39 CEST(dbsrv1) -----------------------------------------------------------------------------
Cloning into 'mariadb-sys'...
2021-05-26 22:25:41 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:25:41 CEST(dbsrv1) INFO: [SUCCESS]  git clone https://github.com/FromDual/mariadb-sys.git  [SUCCESS]
2021-05-26 22:25:41 CEST(dbsrv1) -----------------------------------------------------------------------------
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2)
2021-05-26 22:25:41 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:41 CEST(dbsrv1) END: END SCRIPT: CentOS Linux ENDED SUCCESSFULLY
2021-05-26 22:25:41 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:25:41 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 22:25:41 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 3_config_start.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-26 22:25:41 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
# echo 0
0

```

