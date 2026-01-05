# Documentation des Scripts Utilitaires 📜

Ce document décrit les différents scripts shell disponibles dans le répertoire `docker/mariadb` pour la gestion de l'environnement MariaDB.

## 💾 Sauvegarde & Restauration

### Sauvegarde Logique (`mariadb-dump`)

- **[backup_logical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/backup_logical.sh)** : Effectue un dump SQL compressé.
  - Utilisation : `./backup_logical.sh <galera|repli> [nom_bdd]`
  - Caractéristiques : Utilise `pigz` pour une compression rapide, inclut les routines, triggers et événements.
- **[restore_logical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/restore_logical.sh)** : Restaure une sauvegarde logique.
  - Utilisation : `./restore_logical.sh <galera|repli> <nom_fichier.sql.gz>`

### Sauvegarde Physique (MariaBackup)

- **[backup_physical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/backup_physical.sh)** : Effectue une sauvegarde physique à chaud via MariaBackup.
  - Utilisation : `./backup_physical.sh <galera|repli>`
  - Caractéristiques : Crée un instantané cohérent sans verrouiller la base de données.
- **[restore_physical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/restore_physical.sh)** : Restaure une sauvegarde physique.
  - Utilisation : `./restore_physical.sh <galera|repli> <nom_fichier.tar.gz>`
  - **ATTENTION** : Ce script arrête MariaDB, remplace l'intégralité du répertoire de données et redémarre le service.

## 🔐 Sécurité & SSL

- **[gen_ssl.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/gen_ssl.sh)** : Génère une chaîne complète de certificats SSL (CA, Serveur et Client).
  - Les fichiers sont stockés dans le répertoire `ssl/`.
  - Les certificats sont automatiquement utilisés par les conteneurs via les montages de volumes.

## ⚙️ Configuration & Installation

- **[setup_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/setup_repli.sh)** : Automatise la mise en place de la réplication Maître/Esclave.
  - Effectue la synchronisation initiale des données du Maître vers les Esclaves.
  - Configure la réplication basée sur le GTID.
- **[gen_profiles.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/gen_profiles.sh)** : Génère `profile_galera` et `profile_repli`.
  - Fournit des alias shell (ex: `mariadb-m1`, `mariadb-g1`) pour un accès rapide aux conteneurs.

## 🧪 Tests

- **[test_galera.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_galera.sh)** : Suite complète pour Galera (synchronisation, DDL, conflits).
- **[test_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_repli.sh)** : Vérification pour la réplication Maître/Esclave.
- **[test_perf_galera.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_perf_galera.sh)** / **[test_perf_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_perf_repli.sh)** : Benchmarks de performance utilisant Sysbench.
