# NFS SCRIPTS FOR DB BACKUP

-----------------------

## Target Environments: NFS Server and NFS Clients

- NFS Server: **Ubuntu 20**
- NFS Client: **Ubuntu 18**, **Ubuntu 20**, and **CentOS 7**

## Package Installation Utility Functions (**Ubuntu** & **CentOS**)

`setup_ubuntu_nfs_server()`: Installs packages specialized for the NFS server on **Ubuntu 20**.
`setup_ubuntu_nfs_client()`: Installs packages specialized for the NFS client on **Ubuntu 18 and 20**.
`setup_centos_nfs_client()`: Installs packages specialized for the NFS client on **CentOS 7**.

## NFS Server Management Utility Functions (**Ubuntu 20**)

`createNfsShare()`: Creates an NFS share on **Ubuntu 20**.
`removeNfsShare()`: Removes an NFS share on **Ubuntu 20**.

## NFS Client Management Utility Functions (**Ubuntu 18/20** & **CentOS 7**)

`mountNfsShare()`: Sets up an NFS mount point.
`umountNfsShare()`: Removes an NFS mount point.

# Demonstration and Validation of Procedures

# POC Machine List

- U20 88.80.185.117 - Ubuntu 20 NFS Server
- U20 85.159.208.89  - Ubuntu 20 NFS Client
- U18 178.79.173.114 - Ubuntu 18 NFS Client
- C7  178.79.171.254 - CentOS 7 NFS Client

## Configuring an NFS Server on **Ubuntu 20**

### Details

#### Creating 4 Mount Points

- One per NFS client
- One global NFS share for all servers

### Package Installation Commands (NFS Server **Ubuntu 20**)

    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_ubuntu_nfs_server
    ...

### Package Installation Commands (NFS Client **Ubuntu 18 or 20**)

    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_ubuntu_nfs_client
    ...

### Package Installation Commands (NFS Client **CentOS 7**)

    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_centos_nfs_client
    ...

### NFS Share Creation Commands (NFS Server)

    ssh root@88.80.185.117
    # source nfs_utils.sh

    # createNfsShare /backups/nfscli1 85.159.208.89
    # createNfsShare /backups/nfscli2 178.79.173.114
    # createNfsShare /backups/nfscli3 178.79.171.254
    # createNfsShare /backups/nfsall 85.159.208.89 178.79.173.114 178.79.171.254

    # cat /etc/exportfs
    ...
    
### NFS Share Removal Commands (NFS Server)

    # source nfs_utils.sh

    # removeNfsShare /backups/nfscli1
    # removeNfsShare /backups/nfscli2
    # removeNfsShare /backups/nfscli3
    # removeNfsShare /backups/nfsall

### NFS Mount Commands - nfscli1 **Ubuntu 20** (NFS Client)

    ssh root@nfscli1
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli1 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### NFS Unmount Commands - nfscli1 **Ubuntu 20** (NFS Client)

    ssh root@nfscli1
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

### NFS Mount Commands - nfscli2 **Ubuntu 18** (NFS Client)

    ssh root@nfscli2
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli2 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### NFS Unmount Commands - nfscli2 **Ubuntu 18** (NFS Client)

    ssh root@nfscli2
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

### NFS Mount Commands - nfscli3 **CentOS 7** (NFS Client)

    ssh root@nfscli3
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli3 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### NFS Unmount Commands - nfscli3 **CentOS 7** (NFS Client)

    ssh root@nfscli3
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

## Performed Tests

    - Simple mount attempt
                   => fstab entry ok
                   => mount point ok
    - Double mount attempt
                   => No double fstab entry
                   => mount point ok
    - Unmount attempt
                   => No nfs entry left
    - Double unmount attempt
                   => No mount point
                   => No nfs entry left
    - Attempt to mount a point from another server
                   => No wrong /etc/fstab entry
                   => No mount point

    - Read and write tests between client mount points OK
