# NFS SCRIPTS POUR LA SAUVEGARDE BDD
----------------------- 

## Environnements cible serveur NFS et clients NFS
- Serveur NFS en **Ubuntu 20**
- Client NFS: **Ubuntu 18**, **Ubuntu 20** et **CentOS 7** 

## Fonctions utilitaires d'installation des paquets **Ubuntu** & **CentOS**
``setup_ubuntu_nfs_server()``: Installation des paquets dédiés au serveur NFS **Ubuntu 20** 
``setup_ubuntu_nfs_client()``: Installation des paquets dédiés au client NFS  **Ubuntu 18 et 20**
``setup_centos_nfs_client()``: Installation des paquets dédiés au serveur NFS **CentOS 7**

## Fonctions utilitaires serveur NFS de gestion des partages NFS **Ubuntu 20**
``createNfsShare()``: Création d'un partage NFS  ** Ubuntu 20**
``removeNfsShare()``: Suppression d'un partage NFS  ** Ubuntu 20**

## Fonctions utilitaires client NFS de gestion des partages NFS **Ubuntu 18/20** & **CentOS 7**
``mountNfsShare()``: Installation d'un point de montage NFS
``umountNfsShare()``: Suppression d'un point de montage NFS

# Démonstration et validation des procédures

# Liste des machines du POC
 - U20  88.80.185.117 - Serveur NFS Ubuntu 20
 - U20 85.159.208.89  - Client NFS Ubuntu 20
 - U18 178.79.173.114 - Client NFS Ubuntu 18
 - C7  178.79.171.254 - Client NFS CentOS 7

## Configuration d'un serveur NFS **Ubuntu 20**

### Détails 
#### Création de 4 points de montage 
  - Un par client NFS 
  - Un partage NFS global à tous les serveurs

### Commandes d'installation des paquets NFS serveur ** Ubuntu 20**
    
    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_ubuntu_nfs_server
    ...

### Commandes d'installation des paquets NFS client  ** Ubuntu 18 ou 20**
    
    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_ubuntu_nfs_client
    ...

### Commandes d'installation des paquets NFS client  ** CentOS 7**
    
    ssh root@88.80.185.117
    # source nfs_utils.sh

    # setup_centos_nfs_client
    ...

### Commandes de création des partages NFS (Serveur NFS)
    ssh root@88.80.185.117
    # source nfs_utils.sh

    # createNfsShare /backups/nfscli1 85.159.208.89
    # createNfsShare /backups/nfscli2 178.79.173.114
    # createNfsShare /backups/nfscli3  178.79.171.254
    # createNfsShare /backups/nfsall 85.159.208.89 178.79.173.114 178.79.171.254

    # cat /etc/exportfs
    ...
    
### Commandes de suppression des partages NFS  (Serveur NFS)
    # source nfs_utils.sh

    # removeNfsShare /backups/nfscli1
    # removeNfsShare /backups/nfscli2
    # removeNfsShare /backups/nfscli3
    # removeNfsShare /backups/nfsall

### Commandes de montage NFS - serveur nfscli1 **Ubuntu 20**  (Client NFS)
    ssh root@nfscli1
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli1 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### Commandes de démontage NFS - serveur nfscli1 **Ubuntu 20**  (Client NFS)
    ssh root@nfscli1
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

### Commandes de montage NFS - serveur nfscli2 **Ubuntu 18**  (Client NFS)
    ssh root@nfscli2
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli2 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### Commandes de démontage NFS - serveur nfscli2 **Ubuntu 18**  (Client NFS)
    ssh root@nfscli2
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

### Commandes de montage NFS - serveur nfscli3 **CentOS 7**  (Client NFS)
    ssh root@nfscli3
    # source nfs_utils.sh

    # mountNfsShare 88.80.185.117 /backups/nfscli3 /backups
    # mountNfsShare 88.80.185.117 /backups/nfsall /nfsshare

### Commandes de démontage NFS - serveur nfscli3 **CentOS 7**  (Client NFS)
    ssh root@nfscli3
    # source nfs_utils.sh

    # umountNfsShare /backups
    # umountNfsShare /nfsshare

## Les tests réalisés
    - tentative de montage simple
                   => entrée fstab ok
                   => point de montage ok
    - tentative de montage en double
                   => Pas de double entrée fstab
                   => point de montage ok
    - tentative de démontage
                   => Plus d'entrée nfs
    - tentative de démontage en double
                   => Pas de point de montage
                   => Plus d'entrée nfs
    -tentative de montage d'un point d'un autre serveur
                   => Pas de mauvaise entrée /etc/fstab
                   => Pas de point de montage

    - tentative lecture et écriture entre les points de montage client OK
                
