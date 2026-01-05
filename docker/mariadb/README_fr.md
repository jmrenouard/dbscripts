# Environnement Docker MariaDB 🚀

Ce dépôt propose un environnement MariaDB complet basé sur MariaDB 11.8, optimisé pour le développement et le test d'architectures complexes telles que le **Cluster Galera** et la **Réplication Maître/Esclave**.

---

## 🚀 1. Mise en route

### Construire l'image de base

Commencez par construire l'image personnalisée `mariadb_ssh` contenant tous les outils DBA nécessaires.

```bash
make build-image
```

### Installer le Client (Optionnel)

Pour interagir avec les bases de données depuis votre hôte (Ubuntu/Debian), vous pouvez installer les outils client :

```bash
make install-client
```

### Déployer les Clusters

Choisissez votre scénario et démarrez l'environnement via Docker Compose :

#### 🌐 Cluster Galera (Multi-Maître)

3 nœuds synchrones avec un réseau interne dédié.

```bash
make up-galera
```

#### 🔄 Cluster de Réplication (Maître/Esclaves)

Topologie avec 1 Maître et 2 Esclaves.

```bash
make up-repli
```

---

## 🛠️ 2. Utilisation du Makefile

Le `Makefile` simplifie la gestion des clusters et l'exécution des outils.

| Commande | Description |
| :--- | :--- |
| `make up-galera` / `up-repli` | Démarrer le cluster choisi |
| `make bootstrap-galera` | Initialiser (Bootstrap) un NOUVEAU cluster Galera |
| `make down-galera` / `down-repli` | Arrêter et supprimer les conteneurs |
| `make logs-galera` / `logs-repli` | Suivre les logs du cluster |
| `make test-galera` / `test-repli` | Exécuter les tests de vérification fonctionnelle |
| `make test-lb-galera` | Tester la répartition de charge (HAProxy) pour Galera |
| `make setup-repli` | Configurer la topologie de réplication (Maître/Esclaves) |
| `make backup-galera` / `backup-repli` | Effectuer une sauvegarde logique |
| `make test-perf-galera` / `test-perf-repli` | Exécuter les benchmarks de performance |
| `make gen-profiles` | Générer des fichiers de profil shell avec des alias |

### 🛠️ Alias Shell (Accès Rapide)

Pour accéder facilement aux instances MariaDB depuis votre terminal sans taper l'hôte et le port à chaque fois :

1. Générer les profils :

   ```bash
   make gen-profiles
   ```

2. Charger le profil souhaité :

   ```bash
   source profile_repli   # Pour les alias de Réplication
   # OU
   source profile_galera  # Pour les alias de Galera
   ```

3. Utiliser les alias : `mariadb-m1`, `mariadb-s1`, `mariadb-g1`, `mariadb-lb`, etc.

---

## 💾 3. Sauvegarde & Restauration

Des scripts dédiés gèrent les sauvegardes logiques (SQL) et physiques (Binaires).

### 3.1 Sauvegarde Logique (mariadb-dump)

Dumps SQL compressés avec `pigz`.

- **Galera** : `make backup-galera [DB=nom]` (Stocké dans `/backups`)
- **Réplication** : `make backup-repli [DB=nom]` (Effectué sur un Esclave)
- **Restauration** : `make restore-galera FILE=xxx.sql.gz` ou `make restore-repli FILE=xxx.sql.gz`

### 3.2 Sauvegarde Physique (MariaBackup)

Sauvegardes binaires rapides pour les bases de données volumineuses.

- **Galera** : `make backup-phys-galera`
- **Réplication** : `make backup-phys-repli`
- **Restauration** : `make restore-phys-galera FILE=xxx.tar.gz` (Arrête MariaDB, remplace les données)

---

## 🧪 4. Tests Fonctionnels

Validez la santé et les fonctionnalités du cluster via des scripts automatisés.

### 4.1 Tests du Cluster Galera

Vérifie la connectivité des nœuds, la réplication synchrone, la propagation du DDL et la résolution des conflits.

```bash
make test-galera
```

### 4.2 Tests de la Réplication

Vérifie le statut Maître/Esclave et la cohérence des données sur tous les esclaves.

```bash
make test-repli
```

---

## 🏎️ 5. Tests de Performance (Sysbench)

Mesurez les performances du cluster et générez des rapports HTML premium avec des visualisations détaillées.

### Exécuter les Benchmarks

- **Galera** : `make test-perf-galera PROFILE=standard ACTION=run`
- **Réplication** : `make test-perf-repli PROFILE=standard ACTION=run`

### Profils Disponibles

- `light` : Vérification rapide (1 000 lignes)
- `standard` : Benchmark par défaut (100 000 lignes)
- `read` : Charge intensive en lecture
- `write` : Charge intensive en écriture

### Fonctionnalités des Rapports

Les rapports détaillés incluent des graphiques de latence (ms), la répartition des requêtes (Lecture/Écriture/Autre) et des statistiques de santé spécifiques au cluster (conflits Galera ou lag de réplication).

---

## ⚙️ 6. Configuration Avancée & Accès

### Persistance & Configuration

- **Dossiers de données** : `gdatadir_*` (Galera) ou `datadir_*` (Réplication)
- **Configuration personnalisée** : Modifiez `gcustom_X.cnf` ou `custom_X.cnf` pour régler les paramètres InnoDB ou Galera.

### Accès & Sécurité

- **SSH** : Utilisateur `root`, Mot de passe `rootpass`. Le mappage des ports commence à partir de 22001.
- **MySQL** : Utilisateur `root`, Mot de passe `rootpass`.
- **Répartition de charge** : HAProxy fournit des points d'entrée unifiés.
  - Galera : `localhost:3306`
  - Réplication : `localhost:3406` (Écriture), `localhost:3407` (Lecture)

---

## 📝 7. Dépannage

Les journaux (logs) sont gérés via Supervisor à l'intérieur des conteneurs :

- `/var/log/supervisor/mariadb.err.log`

---

## 📚 8. Documentation Détaillée

Pour des informations plus approfondies, veuillez consulter les documents suivants dans le répertoire [documentation/](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/) :

- **[Architecture](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/architecture_fr.md)** : Topologie globale et schémas Mermaid.
- **[Référence du Makefile](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/makefile_fr.md)** : Détail de toutes les tâches `make`.
- **[Scripts Utilitaires](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/scripts_fr.md)** : Description des scripts de sauvegarde, SSL et installation.
- **[SSL & Réplication](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/replication_ssl_fr.md)** : Configuration de la sécurité et vérification.
- **[Bootstrap Galera](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/galera_bootstrap_fr.md)** : Guide étape par étape pour les nouveaux clusters.
- **[Installation de la Réplication](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/replication_setup_fr.md)** : Explication de l'automatisation de la réplication.
- **[Cas de Tests](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/documentation/tests_fr.md)** : Descriptions des tests automatisés et résultats attendus.
