# Référence du Makefile 🛠️

Le `Makefile` est le point d'entrée principal pour la gestion des clusters Galera et de Réplication.

## 🛠️ Commandes Globales

| Commande | Description |
| :--- | :--- |
| `make help` | Affiche le message d'aide pour toutes les tâches disponibles. |
| `make build-image` | Construit l'image de base `mariadb_ssh:004`. |
| `make install-client` | Installe le client MariaDB sur l'hôte (Ubuntu/Debian). |
| `make gen-ssl` | Génère les certificats SSL dans le répertoire `ssl/`. |
| `make clean-ssl` | Supprimer les certificats générés. |
| `make gen-profiles` | Générer des profils shell pour un accès rapide aux conteneurs. |
| `make clean-galera` | Arrêter Galera et supprimer toutes ses données/sauvegardes. |
| `make clean-repli` | Arrêter la Réplication et supprimer toutes ses données/sauvegardes. |
| `make clean-data` | **DANGER** : Supprimer TOUTES les données, sauvegardes et répertoires SSL. |
| `make full-repli` | Orchestration complète pour la Réplication : Nettoyage, Lancement, Configuration et Test. |
| `make full-galera` | Orchestration complète pour Galera : Nettoyage, Lancement (Bootstrap) et Test. |

## 🌐 Commandes pour le Cluster Galera

| Commande | Description |
| :--- | :--- |
| `make up-galera` | Démarre les nœuds du cluster Galera et HAProxy. |
| `make bootstrap-galera`| Initialise séquentiellement un nouveau cluster (assure que le nœud 1 est le primaire). |
| `make down-galera` | Arrête et supprime le cluster Galera. |
| `make logs-galera` | Affiche les logs en temps réel pour le cluster Galera. |
| `make test-galera` | Exécute la suite de tests fonctionnels Galera. |
| `make test-lb-galera` | Teste spécifiquement l'équilibreur de charge HAProxy pour Galera. |
| `make backup-galera` | Effectuer une sauvegarde SQL logique. |
| `make backup-phys-galera`| Effectuer une sauvegarde physique (MariaBackup). |
| `make restore-galera` | Restaurer une sauvegarde SQL logique. |
| `make restore-phys-galera`| Restaurer une sauvegarde physique (MariaBackup). |
| `make test-perf-galera`| Exécuter les benchmarks Sysbench (Usage : `make test-perf-galera PROFILE=light ACTION=run`). |

## 🔄 Commandes pour le Cluster de Réplication

| Commande | Description |
| :--- | :--- |
| `make up-repli` | Démarre les nœuds du cluster de réplication et HAProxy. |
| `make setup-repli` | Configure la relation Maître/Esclave et la synchronisation initiale. |
| `make down-repli` | Arrête et supprime le cluster de réplication. |
| `make logs-repli` | Affiche les logs en temps réel pour le cluster de réplication. |
| `make test-repli` | Exécute la suite de tests fonctionnels de réplication. |
| `make backup-repli` | Effectuer une sauvegarde SQL logique (sur un esclave). |
| `make backup-phys-repli`| Effectuer une sauvegarde physique (MariaBackup). |
| `make restore-repli` | Restaurer une sauvegarde SQL logique. |
| `make restore-phys-repli`| Restaurer une sauvegarde physique (MariaBackup). |
| `make test-perf-repli` | Exécuter les benchmarks Sysbench (Usage : `make test-perf-repli PROFILE=light ACTION=run`). |
