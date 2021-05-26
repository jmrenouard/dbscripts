# Standard Operations: Setup firewall on Linux with firewalld or iptables

## Table of contents
- [Main document target](#main-document-target)
- [Scripted and remote update procedure](#scripted-and-remote-update-procedure)
- [Update Procedure example remotely](#update-procedure-example-remotely)

## Main document target

> Configure firewall and allow main useful TCP ports to insure hight security level

## Scripted and remote update procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec db* scripts/1_system/2_iptables.sh |
| 3 | Check return code | root | echo $? (0) |

##  Update Procedure example remotely
```bash
# vssh_exec db* scripts/1_system/2_iptables.sh 
2021-05-26 11:38:51 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 2_iptables.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-26 11:38:51 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-26 09:38:51 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:51 UTC(dbsrv1) START: BEGIN SCRIPT: INLINE SHELL
2021-05-26 09:38:51 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:51 UTC(dbsrv1) INFO:  run as root@dbsrv1
2021-05-26 09:38:51 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:51 UTC(dbsrv1) RUNNING COMMAND: timeout 10 systemctl restart firewalld
2021-05-26 09:38:51 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:51 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:51 UTC(dbsrv1) INFO: [SUCCESS]  timeout 10 systemctl restart firewalld  [SUCCESS]
2021-05-26 09:38:52 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:52 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:52 UTC(dbsrv1) RUNNING COMMAND: firewall-cmd --add-port=3306/tcp --permanent
2021-05-26 09:38:52 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:52 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:52 UTC(dbsrv1) INFO: [SUCCESS]  firewall-cmd --add-port=3306/tcp --permanent  [SUCCESS]
2021-05-26 09:38:52 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) RUNNING COMMAND: firewall-cmd --add-port=4444/tcp --permanent
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:53 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:53 UTC(dbsrv1) INFO: [SUCCESS]  firewall-cmd --add-port=4444/tcp --permanent  [SUCCESS]
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) RUNNING COMMAND: firewall-cmd --add-port=4567/tcp --permanent
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:53 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:53 UTC(dbsrv1) INFO: [SUCCESS]  firewall-cmd --add-port=4567/tcp --permanent  [SUCCESS]
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) RUNNING COMMAND: firewall-cmd --add-port=4568/tcp --permanent
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:53 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:53 UTC(dbsrv1) INFO: [SUCCESS]  firewall-cmd --add-port=4568/tcp --permanent  [SUCCESS]
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:53 UTC(dbsrv1) RUNNING COMMAND: firewall-cmd --add-port=5555/tcp --permanent
2021-05-26 09:38:54 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:54 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 09:38:54 UTC(dbsrv1) INFO: [SUCCESS]  firewall-cmd --add-port=5555/tcp --permanent  [SUCCESS]
2021-05-26 09:38:54 UTC(dbsrv1) -----------------------------------------------------------------------------
success
2021-05-26 09:38:54 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 09:38:54 UTC(dbsrv1) END: END SCRIPT: INLINE SHELL ENDED SUCCESSFULLY
2021-05-26 09:38:54 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 11:38:55 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 11:38:55 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 2_iptables.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-26 11:38:55 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 11:38:56 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 2_iptables.sh ON dbsrv2(192.168.33.192) SERVER
2021-05-26 11:38:56 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
Warning: Permanently added '192.168.33.192' (ECDSA) to the list of known hosts.
2021-05-26 09:38:55 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:55 UTC(dbsrv2) START: BEGIN SCRIPT: INLINE SHELL
2021-05-26 09:38:55 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:55 UTC(dbsrv2) INFO:  run as root@dbsrv2
2021-05-26 09:38:55 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:55 UTC(dbsrv2) RUNNING COMMAND: timeout 10 systemctl restart firewalld
2021-05-26 09:38:55 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:56 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:56 UTC(dbsrv2) INFO: [SUCCESS]  timeout 10 systemctl restart firewalld  [SUCCESS]
2021-05-26 09:38:56 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:56 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:56 UTC(dbsrv2) RUNNING COMMAND: firewall-cmd --add-port=3306/tcp --permanent
2021-05-26 09:38:56 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:57 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:57 UTC(dbsrv2) INFO: [SUCCESS]  firewall-cmd --add-port=3306/tcp --permanent  [SUCCESS]
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) RUNNING COMMAND: firewall-cmd --add-port=4444/tcp --permanent
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:57 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:57 UTC(dbsrv2) INFO: [SUCCESS]  firewall-cmd --add-port=4444/tcp --permanent  [SUCCESS]
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) RUNNING COMMAND: firewall-cmd --add-port=4567/tcp --permanent
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:57 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:57 UTC(dbsrv2) INFO: [SUCCESS]  firewall-cmd --add-port=4567/tcp --permanent  [SUCCESS]
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:57 UTC(dbsrv2) RUNNING COMMAND: firewall-cmd --add-port=4568/tcp --permanent
2021-05-26 09:38:57 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:58 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:58 UTC(dbsrv2) INFO: [SUCCESS]  firewall-cmd --add-port=4568/tcp --permanent  [SUCCESS]
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:58 UTC(dbsrv2) RUNNING COMMAND: firewall-cmd --add-port=5555/tcp --permanent
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:58 UTC(dbsrv2) INFO: RETURN CODE: 0
2021-05-26 09:38:58 UTC(dbsrv2) INFO: [SUCCESS]  firewall-cmd --add-port=5555/tcp --permanent  [SUCCESS]
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
success
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 09:38:58 UTC(dbsrv2) END: END SCRIPT: INLINE SHELL ENDED SUCCESSFULLY
2021-05-26 09:38:58 UTC(dbsrv2) -----------------------------------------------------------------------------
2021-05-26 11:38:59 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 11:38:59 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 2_iptables.sh ON dbsrv2(192.168.33.192) SERVER ENDED SUCCESSFULLY
2021-05-26 11:38:59 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 11:39:00 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 2_iptables.sh ON dbsrv3(192.168.33.193) SERVER
2021-05-26 11:39:00 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
Warning: Permanently added '192.168.33.193' (ECDSA) to the list of known hosts.
2021-05-26 09:38:59 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:38:59 UTC(dbsrv3) START: BEGIN SCRIPT: INLINE SHELL
2021-05-26 09:38:59 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:38:59 UTC(dbsrv3) INFO:  run as root@dbsrv3
2021-05-26 09:38:59 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:38:59 UTC(dbsrv3) RUNNING COMMAND: timeout 10 systemctl restart firewalld
2021-05-26 09:38:59 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:00 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:00 UTC(dbsrv3) INFO: [SUCCESS]  timeout 10 systemctl restart firewalld  [SUCCESS]
2021-05-26 09:39:00 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:00 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:00 UTC(dbsrv3) RUNNING COMMAND: firewall-cmd --add-port=3306/tcp --permanent
2021-05-26 09:39:00 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:01 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:01 UTC(dbsrv3) INFO: [SUCCESS]  firewall-cmd --add-port=3306/tcp --permanent  [SUCCESS]
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:01 UTC(dbsrv3) RUNNING COMMAND: firewall-cmd --add-port=4444/tcp --permanent
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:01 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:01 UTC(dbsrv3) INFO: [SUCCESS]  firewall-cmd --add-port=4444/tcp --permanent  [SUCCESS]
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:01 UTC(dbsrv3) RUNNING COMMAND: firewall-cmd --add-port=4567/tcp --permanent
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:01 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:01 UTC(dbsrv3) INFO: [SUCCESS]  firewall-cmd --add-port=4567/tcp --permanent  [SUCCESS]
2021-05-26 09:39:01 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:02 UTC(dbsrv3) RUNNING COMMAND: firewall-cmd --add-port=4568/tcp --permanent
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:02 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:02 UTC(dbsrv3) INFO: [SUCCESS]  firewall-cmd --add-port=4568/tcp --permanent  [SUCCESS]
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:02 UTC(dbsrv3) RUNNING COMMAND: firewall-cmd --add-port=5555/tcp --permanent
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:02 UTC(dbsrv3) INFO: RETURN CODE: 0
2021-05-26 09:39:02 UTC(dbsrv3) INFO: [SUCCESS]  firewall-cmd --add-port=5555/tcp --permanent  [SUCCESS]
2021-05-26 09:39:02 UTC(dbsrv3) -----------------------------------------------------------------------------
success
2021-05-26 09:39:03 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 09:39:03 UTC(dbsrv3) END: END SCRIPT: INLINE SHELL ENDED SUCCESSFULLY
2021-05-26 09:39:03 UTC(dbsrv3) -----------------------------------------------------------------------------
2021-05-26 11:39:04 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 11:39:04 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 2_iptables.sh ON dbsrv3(192.168.33.193) SERVER ENDED SUCCESSFULLY
2021-05-26 11:39:04 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------

# echo $?
0

```
