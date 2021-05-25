# Standard Operations: Update System

## Table of contents
- [Main document target](#main-document-target)
- [Main update Procedure for Red Hat Family OS](#main-update-procedure-for-red-hat-family-os)
- [Main update Procedure for Debian Family OS](#main-update-procedure-for-debian-family-os)
- [Big cleanup procedure](#big-cleanup-procedure)
- [Update Procedure example for Red Hat Family OS](#update-procedure-example-for-red-hat-family-os)
- [Update Procedure example for Debian Family OS](#update-procedure-example-for-debian-family-os)
- [Update Procedure example remotely](#update-procedure-example-remotely)

## Main document target

> Update system packages to insure hight security level


## Main update Procedure for Red Hat Family OS
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Update package information | root | # yum clean all |
| 2 | Download and install all new package avalaible | root | # yum -y update |
| 3 | Check return code | root | echo $? (0) |

## Main update Procedure for Debian Family OS
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Update package information | root | # apt update |
| 2 | Download and install all new package avalaible | root | # apt upgrade -y |
| 3 | Check return code | root | echo $? (0) |

## Big cleanup procedure
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv1 scripts/1_system/1_update.sh |
| 3 | Check return code | root | echo $? (0) |

##  Update Procedure example for Red Hat Family OS
```bash
# yum clean all
...
...
# echo $?
0

# yum -y update
...
# echo $?
0
```

##  Update Procedure example for Debian Family OS
```bash
# apt update
...
...
# echo $?
0

# apt upgrade -y
...
# echo $?
0
```

##  Update Procedure example remotely
```bash
# vssh_exec dbsrv1 scripts/1_system/1_update.sh
2021-05-25 19:16:57 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 1_update.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-25 19:16:57 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-25 17:16:55 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:55 UTC(dbsrv1) START: BEGIN SCRIPT: INLINE SHELL
2021-05-25 17:16:55 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:55 UTC(dbsrv1) INFO:  run as root@dbsrv1
2021-05-25 17:16:55 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:55 UTC(dbsrv1) UPDATE PACKAGE LIST
2021-05-25 17:16:55 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:55 UTC(dbsrv1) INFO: RUNNING COMMAND: yum -y update
2021-05-25 17:16:55 UTC(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 1:29:30 ago on Tue 25 May 2021 03:47:26 PM UTC.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-25 17:16:57 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-25 17:16:57 UTC(dbsrv1) INFO: [SUCCESS]  UPDATE PACKAGE LIST  [SUCCESS]
2021-05-25 17:16:57 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:57 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:57 UTC(dbsrv1) UPDATE PACKAGES
2021-05-25 17:16:57 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:57 UTC(dbsrv1) INFO: RUNNING COMMAND: yum -y upgrade
2021-05-25 17:16:57 UTC(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 1:29:31 ago on Tue 25 May 2021 03:47:26 PM UTC.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-25 17:16:58 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-25 17:16:58 UTC(dbsrv1) INFO: [SUCCESS]  UPDATE PACKAGES  [SUCCESS]
2021-05-25 17:16:58 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:58 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:58 UTC(dbsrv1) INSTALL FIREWALLD
2021-05-25 17:16:58 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:58 UTC(dbsrv1) INFO: RUNNING COMMAND: yum -y install firewalld
2021-05-25 17:16:58 UTC(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 1:29:32 ago on Tue 25 May 2021 03:47:26 PM UTC.
Package firewalld-0.8.2-2.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-25 17:16:59 UTC(dbsrv1) INFO: RETURN CODE: 0
2021-05-25 17:16:59 UTC(dbsrv1) INFO: [SUCCESS]  INSTALL FIREWALLD  [SUCCESS]
2021-05-25 17:16:59 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:59 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 17:16:59 UTC(dbsrv1) END: END SCRIPT: CentOS Linux ENDED SUCCESSFULLY
2021-05-25 17:16:59 UTC(dbsrv1) -----------------------------------------------------------------------------
2021-05-25 19:17:01 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-25 19:17:01 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 1_update.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-25 19:17:01 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------

# echo $?
0

```