# STUNNEL SCRIPTS FOR DB BACKUP
----------------------- 

## Target Environments: Stunnel Server and Clients
- Stunnel Server: **Ubuntu 20**
- Stunnel Clients: **Ubuntu 18**, **Ubuntu 20**, and **CentOS 7**

## Package Installation Utility Functions (**Ubuntu** & **CentOS**)
``setup_ubuntu_stunnel_server()``: Installs packages dedicated to the Stunnel server on **Ubuntu 20**.

``setup_ubuntu_stunnel_client()``: Installs packages dedicated to the Stunnel client on **Ubuntu 18 and 20**.

``setup_centos_stunnel_client()``: Installs packages dedicated to the Stunnel client on **CentOS 7**.

## Stunnel Server Share Management Utility Functions (**Ubuntu 20**)
``gen_stunnel_cert()``: Generates the TLS tunnel PEM certificate (**Ubuntu 20**).

``gen_stunnel_server_conf()``: Configures Stunnel for NFS on the server side (**Ubuntu 20**).

``push_cert_config``: Distributes the certificate to Stunnel clients (**Ubuntu 20**).

``gen_stunnel_client_conf()``: Configures Stunnel for NFS on the client side (**Ubuntu 20**).

# Demonstration and Validation of Procedures

# POC Machine List
 - U20  176.58.120.128 - Ubuntu 20 Stunnel Server
 - U20  178.79.190.100 - Ubuntu 20 Stunnel Client
 - U18  109.237.26.75  - Ubuntu 18 Stunnel Client
 - C70  178.79.190.154 - CentOS 7 Stunnel Client

## Configuring a Stunnel Server on **Ubuntu 20**

### Details
#### Creating 4 Mount Points
  - One per Stunnel client
  - One global Stunnel share for all servers

### Package Installation Commands (Stunnel Server **Ubuntu 20**)
    
    ssh root@176.58.120.128
    # source stunnel_utils.sh

    # setup_ubuntu_stunnel_server
    ...

### Package Installation Commands (Stunnel Client **Ubuntu 18 or 20**)
    
    ssh root@178.79.190.100
    # source stunnel_utils.sh

    # setup_ubuntu_stunnel_client
    ...

### Package Installation Commands (Stunnel Client **CentOS 7**)
    
    ssh root@178.79.190.154
    # source stunnel_utils.sh

    # setup_centos_stunnel_client
    ...

### Stunnel Share Creation Commands (Stunnel Server)
    ssh root@176.58.120.128
    # source stunnel_utils.sh

    # gen_stunnel_cert
    # gen_stunnel_server_conf

    ...
    
### Certificate Distribution Commands to Client Servers (Stunnel Server)
    ssh root@176.58.120.128
    # source stunnel_utils.sh
    # push_cert_config 178.79.190.100

### Stunnel Client Configuration Commands - Server cli1 **Ubuntu 20** (Stunnel Client)
    ssh root@cli1
    # source stunnel_utils.sh

    # gen_stunnel_client_conf 176.58.120.128

## Performed Tests
    - Simple mount attempt
                   => systemctl entry ok
                   => mount point ok
    - Double mount attempt
                   => mount point ok
    - Unmount attempt
                   => No Stunnel entry remaining
    - Double unmount attempt
                   => No mount point
                   => No Stunnel entry remaining
    - Attempt to mount a share from another server
                   => No mount point
                   => No systemctl mount service file remaining
    - Read and write test between client mount points OK
