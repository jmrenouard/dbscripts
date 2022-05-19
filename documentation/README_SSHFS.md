# SSHFS SCRIPTS POUR LA SAUVEGARDE BDD
----------------------- 

## Environnements cible serveur SSH et clients SSHFS
- Serveur SSHFS en **Ubuntu 20**
- Client SSHFS: **Ubuntu 18**, **Ubuntu 20** et **CentOS 7** 

## Fonctions utilitaires d'installation des paquets **Ubuntu** & **CentOS**
``setup_ubuntu_sshfs_server()``: Installation des paquets dédiés au serveur SSHFS **Ubuntu 20** 
``setup_ubuntu_sshfs_client()``: Installation des paquets dédiés au client SSHFS  **Ubuntu 18 et 20**
``setup_centos_sshfs_client()``: Installation des paquets dédiés au serveur SSHFS **CentOS 7**


## Fonctions utilitaires serveur SSHFS de gestion des partages SSHFS **Ubuntu 20**
``createSSHFSShare()``: Création d'un partage SSHFS  ** Ubuntu 20**
``removeSSHFSShare()``: Suppression d'un partage SSHFS  ** Ubuntu 20**

## Fonctions utilitaires client SSHFS de gestion des partages SSHFS **Ubuntu 18/20** & **CentOS 7**
``mountSSHFSShare()``: Installation d'un point de montage SSHFS
``umountSSHFSShare()``: Suppression d'un point de montage SSHFS

# Démonstration et validation des procédures

# Liste des machines du POC
 - U20  176.58.120.128 - Serveur SSHFS Ubuntu 20
 - U20  178.79.190.100 - Client SSHFS Ubuntu 20
 - U18  109.237.26.75  - Client SSHFS Ubuntu 18
 - C70  178.79.190.154 - Client SSHFS CentOS 7

## Configuration d'un serveur SSHFS **Ubuntu 20**

### Détails 
#### Création de 4 points de montage 
  - Un par client SSHFS 
  - Un partage SSHFS global à tous les serveurs

### Commandes d'installation des paquets SSHFS serveur ** Ubuntu 20**
    
`
    ssh root@176.58.120.128
    # source sshfs_utils.sh

    # setup_ubuntu_sshfs_server
    ...
`

### Commandes d'installation des paquets SSHFS client  ** Ubuntu 18 ou 20**
    
    ssh root@178.79.190.100
    # source sshfs_utils.sh

    # setup_ubuntu_sshfs_client
    ...

### Commandes d'installation des paquets SSHFS client  ** CentOS 7**
    
    ssh root@178.79.190.154
    # source sshfs_utils.sh

    # setup_centos_sshfs_client
    ...

### Commandes de création des partages SSHFS (Serveur SSHFS)
    ssh root@176.58.120.128
    # source sshfs_utils.sh

    # create_sshfs_share backups rw
    # create_sshfs_share share ro


    # ls -lsh / | grep -E '(share|backups)' 
    ...
    
### Commandes de d'envoi des clés sur les serveurs clients (Serveur SSHFS)
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### Commandes de montage SSHFS - serveur SSHFScli1 **Ubuntu 20**  (Client SSHFS)
    ssh root@SSHFScli1
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### Commandes de démontage SSHFS - serveur SSHFScli1 **Ubuntu 20**  (Client SSHFS)
    ssh root@SSHFScli1
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### Commandes de montage SSHFS - serveur SSHFScli2 **Ubuntu 18**  (Client SSHFS)
    ssh root@SSHFScli2
    # source sshfs_utils.sh

    # mount_sshfs_share_share
    # mount_sshfs_share_backup

### Commandes de démontage SSHFS - serveur SSHFScli2 **Ubuntu 18**  (Client SSHFS)
    ssh root@SSHFScli2
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

### Commandes de montage SSHFS - serveur SSHFScli3 **CentOS 7**  (Client SSHFS)
    ssh root@SSHFScli3
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

### Commandes de démontage SSHFS - serveur SSHFScli3 **CentOS 7**  (Client SSHFS)
    ssh root@SSHFScli3
    # source sshfs_utils.sh

    # umount_sshfs_share_share
    # umount_sshfs_share_backup

## Les tests réalisés
    - tentative de montage simple
                   => entrée systemctl ok
                   => point de montage ok
    - tentative de montage en double
                   => point de montage ok
    - tentative de démontage
                   => Plus d'entrée SSHFS
    - tentative de démontage en double
                   => Pas de point de montage
                   => Plus d'entrée SSHFS
    -tentative de montage d'un point d'un autre serveur
                   => Pas de point de montage
                   => Plus de fichier de service mount systemctl
    - tentative lecture et écriture entre les points de montage client OK
                
