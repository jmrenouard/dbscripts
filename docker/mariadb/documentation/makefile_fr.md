# Référence du Makefile 🛠️

Le `Makefile` est le point d'entrée principal pour la gestion des clusters Galera et de Réplication.

## 🛠️ Commandes Globales

| Commande | Description |
| :--- | :--- |
| `make help` | Affiche le message d'aide pour toutes les tâches disponibles. |
| `make build-image` | Construit l'image de base `mariadb_ssh:004`. |
| `make install-client` | Installe le client MariaDB sur l'hôte (Ubuntu/Debian). |
| `make gen-ssl` | Génère les certificats SSL dans le répertoire `ssl/`. |
| `make clean-ssl` | Supprime les certificats générés. |
| `make gen-profiles` | Génère des profils shell pour un accès rapide aux conteneurs. |
| `make clean-data` | **DANGER** : Supprime tous les répertoires de données et de sauvegardes. |

## 🌐 Commandes pour le Cluster Galera

| Commande | Description |
| :--- | :--- |
| `make up-galera` | Démarre les nœuds du cluster Galera et HAProxy. |
| `make bootstrap-galera`| Initialise séquentiellement un nouveau cluster (assure que le nœud 1 est le primaire). |
| `make down-galera` | Arrête et supprime le cluster Galera. |
| `make logs-galera` | Affiche les logs en temps réel pour le cluster Galera. |
| `make test-galera` | Exécute la suite de tests fonctionnels Galera. |
| `make test-lb-galera` | Teste spécifiquement l'équilibreur de charge HAProxy pour Galera. |
| `make backup-galera` | Effectue une sauvegarde logique SQL. |
| `make test-perf-galera`| Exécute les benchmarks Sysbench (Usage : `make test-perf-galera PROFILE=light ACTION=run`). |

## 🔄 Commandes pour le Cluster de Réplication

| Commande | Description |
| :--- | :--- |
| `make up-repli` | Démarre les nœuds du cluster de réplication et HAProxy. |
| `make setup-repli` | Configure la relation Maître/Esclave et la synchronisation initiale. |
| `make down-repli` | Arrête et supprime le cluster de réplication. |
| `make logs-repli` | Affiche les logs en temps réel pour le cluster de réplication. |
| `make test-repli` | Exécute la suite de tests fonctionnels de réplication. |
| `make backup-repli` | Effectue une sauvegarde logique SQL (sur un esclave). |
| `make test-perf-repli` | Exécute les benchmarks Sysbench (Usage : `make test-perf-repli PROFILE=light ACTION=run`). |
