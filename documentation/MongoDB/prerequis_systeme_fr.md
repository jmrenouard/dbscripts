# Prérequis pour MongoDB 8 Operations

## Système de Fichiers
- **Alignement des Partitions de Disque** : Alignez les partitions de disque avec la configuration RAID.
- **Éviter les Disques NFS** : N'utilisez pas de disques NFS pour `dbPath`. Utilisez les disques virtuels VMware au lieu de NFS.
- **Linux/Unix** : Formatez les disques en XFS ou EXT4. Utilisez XFS pour une meilleure performance avec le moteur de stockage WiredTiger.
- **Windows** : Utilisez le système de fichiers NTFS ; évitez les systèmes de fichiers FAT.

## Réplication
- **Provisionnement des Membres** : Assurez-vous que tous les membres de réplica set non cachés sont identiquement provisionnés.
- **Taille de l'Oplog** : Configurez la taille de l'oplog pour couvrir les fenêtres de maintenance, d'arrêt et de restauration.
- **Membres Votants** : Incluez au moins trois membres de réplica set avec journalisation.
- **Concern d'Écriture** : Émettez des écritures avec `w: majority` pour la disponibilité et la durabilité.
- **Configuration Réseau** : Utilisez des noms d'hôtes, assurez-vous de la connectivité réseau bidirectionnelle et résolvez les noms d'hôtes.
- **Membres Votants** : Assurez-vous qu'il y a un nombre impair de membres votants et que chaque instance `mongod` a 0 ou 1 vote.
- **Haute Disponibilité** : Déployez les réplica sets dans au moins trois centres de données.

## Sharding
- **Serveurs de Configuration** : Placez les serveurs de configuration sur du matériel dédié pour une performance optimale dans les grands clusters.
- **Routeurs mongos** : Déployez selon les directives de configuration de production.
- **Synchronisation des Horloges** : Utilisez NTP pour synchroniser les horloges.
- **Connectivité Réseau** : Assurez-vous de la connectivité réseau bidirectionnelle entre `mongod`, `mongos` et les serveurs de configuration.
- **CNAMEs** : Utilisez des CNAMEs pour identifier les serveurs de configuration au cluster afin de pouvoir les renommer et les renuméroter sans interruption.

## Journalisation (Moteur de Stockage WiredTiger)
- **Journalisation** : Assurez-vous que toutes les instances utilisent la journalisation.
- **Placement du Journal** : Placez le journal sur un disque à faible latence pour les charges de travail à écriture intensive.

## Matériel
- **RAID et SSD** : Utilisez RAID10 et des disques SSD pour une performance optimale.

## SAN et Virtualisation
- **Provisionnement des IOPS** : Assurez-vous que chaque `mongod` dispose d'IOPS provisionnées ou d'un propre disque physique/LUN.
- **Fonctionnalités de Mémoire Dynamique** : Évitez les fonctionnalités de mémoire dynamique comme le gonflement de mémoire.
- **Placement SAN** : Évitez de placer tous les membres de réplica set sur le même SAN.

## Déploiements sur Matériel Cloud
- **Windows Azure** : Ajustez le TCP keepalive (`tcp_keepalive_time`) à 100-120.
- **Version MongoDB** : Utilisez MongoDB 2.6.4 ou une version ultérieure pour les systèmes avec un stockage à haute latence.

## Configuration du Système d'Exploitation
### Linux
- **Transparent Hugepages** : Activez pour MongoDB 8.0 ou ultérieur, désactivez pour MongoDB 7.0 ou antérieur.
- **Paramètres de Readahead** : Ajustez les paramètres de readahead sur les périphériques stockant les fichiers de base de données.
- **Planificateurs de Disque** : Utilisez `cfq` ou `deadline` pour les SSD, `cfq` pour les disques virtuels.
- **NUMA** : Désactivez NUMA ou définissez `vm.zone_reclaim_mode` à 0.
- **Valeurs ulimit** : Ajustez les valeurs `ulimit` en fonction de votre cas d'utilisation.
- **Options de Montage** : Utilisez `noatime` pour le point de montage `dbPath`.
- **Paramètres du Noyau** : Configurez `fs.file-max`, `kernel.pid_max`, `kernel.threads-max`, et `vm.max_map_count`.
- **Espace d'Échange** : Configurez l'espace d'échange ou désactivez le swap.
- **TCP Keepalive** : Définissez le TCP keepalive par défaut du système à 120.

### Windows
- **Paramètres NTFS** : Désactivez les mises à jour du "dernier accès" et utilisez la taille d'unité d'allocation par défaut de 4096 octets.

## Sauvegardes
- **Tests Périodiques** : Planifiez des tests périodiques des processus de sauvegarde et de restauration.

## Surveillance
- **Outils de Surveillance** : Utilisez MongoDB Cloud Manager, Ops Manager ou un autre système de surveillance.
- **Métriques Clés** : Surveillez le retard de réplication, la fenêtre de l'oplog, les assertions, les files d'attente, les fautes de page et les statistiques matérielles.
- **Surveillance de l'Espace Disque** : Créez un fichier factice ou utilisez `cron+df` pour les alertes d'espace disque.

## Équilibrage de Charge
- **Sessions Collantes** : Configurez les équilibreurs de charge pour activer les "sessions collantes" ou "affinité client".
- **Placement** : Évitez de placer les équilibreurs de charge entre les composants du cluster ou du réplica set MongoDB.

## Sécurité
- **Mesures de Sécurité** : Suivez la liste de contrôle de sécurité MongoDB pour des mesures supplémentaires.

---

### Commandes et Fichiers de Configuration pour Linux

#### Alignement des Partitions de Disque
```bash
# Vérifiez l'alignement des partitions
sudo fdisk -l
```

#### Formatage des Disques
```bash
# Formatez en XFS
sudo mkfs.xfs /dev/sdX

# Formatez en EXT4
sudo mkfs.ext4 /dev/sdX
```

#### Configuration de l'Oplog
```yaml
# Dans le fichier de configuration mongod.conf
storage:
  journal:
    enabled: true
  oplogSizeMB: 1024  # Ajustez selon vos besoins
```

#### Configuration des Serveurs de Configuration
```yaml
# Dans le fichier de configuration mongod.conf
sharding:
  clusterRole: configsvr
```

#### Configuration des Routeurs mongos
```yaml
# Dans le fichier de configuration mongos.conf
sharding:
  configDB: configReplSet/configsvr01:27019,configsvr02:27019,configsvr03:27019
```

#### Synchronisation des Horloges
```bash
# Installez NTP
sudo apt-get install ntp

# Démarrez et activez le service NTP
sudo systemctl start ntp
sudo systemctl enable ntp
```

#### Configuration des Disques SSD
```bash
# Vérifiez le planificateur de disque actuel
cat /sys/block/sdX/queue/scheduler

# Définissez le planificateur cfq ou deadline
sudo bash -c "echo cfq > /sys/block/sdX/queue/scheduler"
```

#### Désactivation de NUMA
```bash
# Ajoutez les options de démarrage du noyau
sudo grubby --update-kernel=ALL --args="numa=off"
```

#### Ajustement des Valeurs ulimit
```bash
# Ajustez les valeurs ulimit dans /etc/security/limits.conf
mongod soft nofile 64000
mongod hard nofile 64000
mongod soft nproc 64000
mongod hard nproc 64000
```

#### Configuration des Paramètres du Noyau
```bash
# Modifiez les paramètres du noyau dans /etc/sysctl.conf
fs.file-max = 98000
kernel.pid_max = 64000
kernel.threads-max = 64000
vm.max_map_count = 131060

# Appliquez les modifications
sudo sysctl -p
```

#### Désactivation de l'Échange
```bash
# Désactivez l'échange dans /etc/fstab
# Commentez ou supprimez les lignes contenant "swap"

# Désactivez l'échange immédiatement
sudo swapoff -a
```

#### Configuration du TCP Keepalive
```bash
# Modifiez les paramètres TCP dans /etc/sysctl.conf
net.ipv4.tcp_keepalive_time = 120

# Appliquez les modifications
sudo sysctl -p
```