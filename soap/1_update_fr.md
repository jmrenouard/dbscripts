# Opération Standard : Mise à jour du système

## Table des matières
- [Objectifs du document](#objectifs-du-document)
- [Procédure de mise à jourpour les OS de type Red Hat](#procédure-de-mise-à-jourpour-les-os-de-type-red-hat)
- [Procédure de mise à jourpour les OS de type Debian](#procédure-de-mise-à-jourpour-les-os-de-type-debian)
- [Procédure de mise à jour](#procédure-de-mise-à-jour)
- [Exemple de procédure de mise à jour pour OS de type Red Hat](#exemple-de-procédure-de-mise-à-jour-pour-os-de-type-red-hat)
- [Exemple de procédure de mise à jour pour OS de type Debian](#exemple-de-procédure-de-mise-à-jour-pour-os-de-type-debian)
- [Exemple de procédure à distance par script](#exemple-de-procédure-à-distance-par-script)

## Objectifs du document

> Définir la procédure de mise à jour des logiciels installés afin d'assurer un haut niveau de sécurité

## Procédure de mise à jourpour les OS de type Red Hat
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Mise à jour des informations de paquets | root | # yum clean all |
| 2 | Téléchargement et mise à jour des paquets sur le serveur | root | # yum -y update |
| 3 | Vérifier le code retour  | root | echo $? (0) |

## Procédure de mise à jourpour les OS de type Debian
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Mise à jour des informations de paquets | root | # apt update |
| 2 | Téléchargement et mise à jour des paquets sur le serveur | root | # apt upgrade -y |
| 3 | Vérifier le code retour  | root | echo $? (0) |

## Procédure de mise à jour
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv1 scripts/1_system/1_update.sh |
| 3 | Vérifier le code retour  | root | echo $? (0) |

## Exemple de procédure de mise à jour pour OS de type Red Hat
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

## Exemple de procédure de mise à jour pour OS de type Debian 
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

## Exemple de procédure à distance par script
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
2021-05-25 17:16:55 UTC(dbsrv1) INFO: RUNNING Commande: yum -y update
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
2021-05-25 17:16:57 UTC(dbsrv1) INFO: RUNNING Commande: yum -y upgrade
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
2021-05-25 17:16:58 UTC(dbsrv1) INFO: RUNNING Commande: yum -y install firewalld
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
