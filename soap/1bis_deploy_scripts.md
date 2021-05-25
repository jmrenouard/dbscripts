# Standard Operations: Update or install management scripts

## Table of contents
- [Main document target](#main-document-target)
- [Main procedure](#main-procedure)
- [Big cleanup procedure](#big-cleanup-procedure)
- [Cleanup procedure example](#cleanup-procedure-example)
- [Install procedure example](#install-procedure-example)

²
## Main document target

> Install script and utilities in order to be able to manage MariaDB/MySQL properly.


## Main procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Push and install script | root | # vupdateScript dbsrv1 |


## Big cleanup procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Load utilities functions  | root | # vssh_cmd dbsrv1 'rm -rf /opt/local/bin /etc/profile.d/utils.sh' |
| 3 | Push and install script | root | # vupdateScript dbsrv1 |

##  Cleanup procedure example
```bash
# cd dbscripts
# source profile
# vssh_cmd dbsrv1 'rm -rf /opt/local/bin /etc/profile.d/utils.sh'
2021-05-25 18:56:08 CEST(DESKTOP-JPKE7F3) RUNNING UNIX COMMAND: rm -rf /opt/local/bin /etc/profile.d/utils.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-25 18:56:08 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-25 18:56:09 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:56:09 CEST(DESKTOP-JPKE7F3) END: RUNNING UNIX COMMAND: rm -rf /opt/local/bin /etc/profile.d/utils.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-25 18:56:09 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------

# echo $?
0
```

## Install procedure example
```bash
# cd dbscripts
# source profile
# vupdateScript dbsrv1
# vupdateScript dbsrv1
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) START: UPDATE SCRIPTS
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) TRANSFERT utils.sh TO dbsrv1
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) SSH COPY /mnt/c/Users/jmren/Documents/dbscripts/scripts/utils.sh ON dbsrv1(192.168.33.191):/etc/profile.d/utils.sh
2021-05-25 18:57:06 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
sending incremental file list
utils.sh

sent 6,487 bytes  received 35 bytes  4,348.00 bytes/sec
total size is 22,251  speedup is 3.41
dbsrv1  chown -R root:root /etc/profile.d/utils.sh
dbsrv1  chmod -R 755 /etc/profile.d/utils.sh
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) END: SSH COPY /mnt/c/Users/jmren/Documents/dbscripts/scripts/utils.sh ON dbsrv1(192.168.33.191):/etc/profile.d/utils.sh  ENDED SUCCESSFULLY
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) TRANSFERT bin scripts TO dbsrv1
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) SSH COPY /mnt/c/Users/jmren/Documents/dbscripts/scripts/bin/ ON dbsrv1(192.168.33.191):/opt/local/bin
2021-05-25 18:57:08 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
sending incremental file list
created directory /opt/local/bin
./
accept_client.sh
activate_audit_plugin.sh
activate_connect_engine.sh
activate_cracklibpassword_plugin.sh
activate_metadata_lock_plugin.sh
activate_querytime_plugin.sh
activate_simplepassword_plugin.sh
activate_sqlerror_plugin.sh
activate_userstat_plugin.sh
backupinfo.sh
block_client.sh
boucleProxy.sh
calculateGaleraCache.sh
change_serverid.sh
change_wsrep_config.sh
check_tcp.py
check_user_password.sh
check_user_passwords.sh
clustercheck
create_database.sh
create_user.sh
diff_schema.sh
drop_database.sh
drop_user.sh
file_wsrep_notif.sh
findip.py
getsysinfo.sh
ka_service_check.sh
ka_service_notify.sh
lgbackup.sh
lgrestore.sh
lgsetup_slave.sh
list_user.sh
mbbackup.sh
mbrestore.sh
mbsetup_slave.sh
mygenconf.py
mysqlcheck
pitr-backup.sh
pitr-restore.sh
promote_slave.sh
set_password.sh
set_readonly.sh
setup_replication.sh
setup_slave.sh
state_backend.sh
summarize_binlogs.sh
table_wsrep_notif.sh
waitsuplag.sh

sent 32,044 bytes  received 987 bytes  22,020.67 bytes/sec
total size is 70,521  speedup is 2.13
dbsrv1  chown -R root:root /opt/local/bin
dbsrv1  chmod -R 755 /opt/local/bin
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) END: SSH COPY /mnt/c/Users/jmren/Documents/dbscripts/scripts/bin/ ON dbsrv1(192.168.33.191):/opt/local/bin  ENDED SUCCESSFULLY
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) END: UPDATE SCRIPTS ENDED SUCCESSFULLY
2021-05-25 18:57:10 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------

# echo $?
0
```
