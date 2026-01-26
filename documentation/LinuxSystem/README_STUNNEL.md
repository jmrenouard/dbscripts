# STUNNEL SCRIPTS POUR LA SAUVEGARDE BDD
----------------------- 

## Environnements cible serveur SSH et clients STUNNEL
- Serveur STUNNEL en **Ubuntu 20**
- Client STUNNEL: **Ubuntu 18**, **Ubuntu 20** et **CentOS 7** 

## Fonctions utilitaires d'installation des paquets **Ubuntu** & **CentOS**
``setup_ubuntu_stunnel_server()``: Installation des paquets dédiés au serveur stunnel **Ubuntu 20** 

``setup_ubuntu_stunnel_client()``: Installation des paquets dédiés au client stunnel  **Ubuntu 18 et 20**

``setup_centos_stunnel_client()``: Installation des paquets dédiés au serveur stunnel **CentOS 7**

## Fonctions utilitaires serveur STUNNEL de gestion des partages STUNNEL **Ubuntu 20**
``gen_stunnel_cert()``: Génération du certificat PEM du tunnel TLS  ** Ubuntu 20**

``gen_stunnel_server_conf()``: Configuration du stunnel pour NFS  côté serveur ** Ubuntu 20**

``push_cert_config: Envoi du certificat vers les clients Stunnel  ** Ubuntu 20**

``gen_stunnel_client_conf()``: Configuration du stunnel pour NFS côté client  ** Ubuntu 20**

# Démonstration et validation des procédures

# Liste des machines du POC
 - U20  176.58.120.128 - Serveur STUNNEL Ubuntu 20
 - U20  178.79.190.100 - Client STUNNEL Ubuntu 20
 - U18  109.237.26.75  - Client STUNNEL Ubuntu 18
 - C70  178.79.190.154 - Client STUNNEL CentOS 7

## Configuration d'un serveur STUNNEL **Ubuntu 20**

### Détails 
#### Création de 4 points de montage 
  - Un par client STUNNEL 
  - Un partage STUNNEL global à tous les serveurs

### Commandes d'installation des paquets STUNNEL serveur ** Ubuntu 20**
    
    ssh root@176.58.120.128
    # source stunnel_utils.sh

    # setup_ubuntu_stunnel_server
    ...

### Commandes d'installation des paquets STUNNEL client  ** Ubuntu 18 ou 20**
    
    ssh root@178.79.190.100
    # source stunnel_utils.sh

    # setup_ubuntu_stunnel_client
    ...

### Commandes d'installation des paquets STUNNEL client  ** CentOS 7**
    
    ssh root@178.79.190.154
    # source stunnel_utils.sh

    # setup_centos_stunnel_client
    ...

### Commandes de création des partages STUNNEL (Serveur STUNNEL)
    ssh root@176.58.120.128
    # source stunnel_utils.sh

    # gen_stunnel_cert
    # gen_stunnel_server_conf

    ...
    
### Commandes de d'envoi des clés sur les serveurs clients (Serveur STUNNEL)
    ssh root@176.58.120.128
    # source stunnel_utils.sh
    # push_cert_config 178.79.190.100

### Commandes de montage STUNNEL - serveur cli1 **Ubuntu 20**  (Client STUNNEL)
    ssh root@cli1
    # source stunnel_utils.sh

    # gen_stunnel_client_conf 176.58.120.128

## Les tests réalisés
    - tentative de montage simple
                   => entrée systemctl ok
                   => point de montage ok
    - tentative de montage en double
                   => point de montage ok
    - tentative de démontage
                   => Plus d'entrée STUNNEL
    - tentative de démontage en double
                   => Pas de point de montage
                   => Plus d'entrée STUNNEL
    -tentative de montage d'un point d'un autre serveur
                   => Pas de point de montage
                   => Plus de fichier de service mount systemctl
    - tentative lecture et écriture entre les points de montage client OK
                
