# SSHFS SCRIPTS FOR DB BACKUP
----------------------- 

## Target Environments: SSHFS Server and Clients
- SSHFS Server: **Ubuntu 20**
- SSHFS Clients: **Ubuntu 18**, **Ubuntu 20**, and **CentOS 7**

## Package Installation Utility Functions (**Ubuntu** & **CentOS**)
``setup_ubuntu_sshfs_server()``: Installs packages dedicated to the SSHFS server on **Ubuntu 20**.
``setup_ubuntu_sshfs_client()``: Installs packages dedicated to the SSHFS client on **Ubuntu 18 and 20**.
``setup_centos_sshfs_client()``: Installs packages dedicated to the SSHFS client on **CentOS 7**.

## SSHFS Server Share Management Utility Functions (**Ubuntu 20**)
``createSSHFSShare()``: Creates an SSHFS share on **Ubuntu 20**.
``removeSSHFSShare()``: Removes an SSHFS share on **Ubuntu 20**.

## SSHFS Client Mount Management Utility Functions (**Ubuntu 18/20** & **CentOS 7**)
``mountSSHFSShare()``: Configures an SSHFS mount point.
``umountSSHFSShare()``: Removes an SSHFS mount point.

# Demonstration and Validation of Procedures

# POC Machine List
 - U20  176.58.120.128 - Ubuntu 20 SSHFS Server
 - U20  178.79.190.100 - Ubuntu 20 SSHFS Client
 - U18  109.237.26.75  - Ubuntu 18 SSHFS Client
 - C70  178.79.190.154 - CentOS 7 SSHFS Client

## Configuring an SSHFS Server on **Ubuntu 20**

### Details
#### Creating 4 Mount Points
  - One per SSHFS client
  - One global SSHFS share for all servers

### Package Installation Commands (SSHFS Server **Ubuntu 20**)
    
```bash
# ssh root@176.58.120.128
# source sshfs_utils.sh

# setup_ubuntu_sshfs_server
# ...
```

### Package Installation Commands (SSHFS Client **Ubuntu 18 or 20**)
    
    ssh root@178.79.190.100
    # source sshfs_utils.sh

    # setup_ubuntu_sshfs_client
    ...

### Package Installation Commands (SSHFS Client **CentOS 7**)
    
    ssh root@178.79.190.154
    # source sshfs_utils.sh

    # setup_centos_sshfs_client
    ...

### SSHFS Share Creation Commands (SSHFS Server)
    ssh root@176.58.120.128
    # source sshfs_utils.sh

    # create_sshfs_share backups rw
    # create_sshfs_share share ro

    # ls -lsh / | grep -E '(share|backups)' 
    ...
    
### SSH Key Distribution Commands to Client Servers (SSHFS Server)
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### SSHFS Mount Commands - Server SSHFScli1 **Ubuntu 20** (SSHFS Client)
    ssh root@SSHFScli1
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### SSHFS Unmount Commands - Server SSHFScli1 **Ubuntu 20** (SSHFS Client)
    ssh root@SSHFScli1
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

### SSHFS Mount Commands - Server SSHFScli2 **Ubuntu 18** (SSHFS Client)
    ssh root@SSHFScli2
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### SSHFS Unmount Commands - Server SSHFScli2 **Ubuntu 18** (SSHFS Client)
    ssh root@SSHFScli2
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

### SSHFS Mount Commands - Server SSHFScli3 **CentOS 7** (SSHFS Client)
    ssh root@SSHFScli3
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### SSHFS Unmount Commands - Server SSHFScli3 **CentOS 7** (SSHFS Client)
    ssh root@SSHFScli3
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

## Performed Tests
    - Simple mount attempt
                   => systemctl entry ok
                   => mount point ok
    - Double mount attempt
                   => mount point ok
    - Unmount attempt
                   => No SSHFS entry remaining
    - Double unmount attempt
                   => No mount point
                   => No SSHFS entry remaining
    - Attempt to mount a share from another server
                   => No mount point
                   => No systemctl mount service file remaining
    - Read and write test between client mount points OK
