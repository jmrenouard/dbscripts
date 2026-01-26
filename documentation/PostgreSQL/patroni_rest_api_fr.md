# Patroni: Référence de l'API REST

## Table des matières
- [Points de terminaison de test de santé (Health Check)](#points-de-terminaison-de-test-de-santé-(health-check))
- [Surveillance et Métriques](#surveillance-et-métriques)
- [Points de terminaison de gestion du cluster](#points-de-terminaison-de-gestion-du-cluster)
- [Valeurs d'état de PostgreSQL](#valeurs-d'état-de-postgresql)

> Documentation détaillée des points de terminaison de l'API REST Patroni pour les tests de santé, la surveillance et la gestion du cluster.

## Points de terminaison de test de santé (Health Check)

Ces points de terminaison renvoient le code HTTP 200 en cas de succès.

| Méthode | Point de terminaison | Description |
|---|---|---|
| GET | `/` | Test de santé pour le primaire (leader) |
| GET | `/primary` | Test de santé pour le primaire (leader) |
| GET | `/read-write` | Test de santé pour le primaire (leader) |
| GET | `/standby-leader` | Test de santé pour le leader dans un cluster standby |
| GET | `/leader` | Test de santé pour le nœud détenant le verrou de leader |
| GET | `/replica` | Test de santé pour un replica (en cours d'exécution, pas primaire) |
| GET | `/read-only` | Test de santé incluant le primaire et les replicas |
| GET | `/synchronous` / `/sync` | Test de santé pour un standby synchrone |
| GET | `/read-only-sync` | Test de santé incluant le primaire et les standbys synchrones |
| GET | `/quorum` | Test de santé pour un nœud quorum |
| GET | `/read-only-quorum` | Test de santé incluant le primaire et les nœuds quorum |
| GET | `/asynchronous` / `/async` | Test de santé pour un standby asynchrone |
| GET | `/health` | Test de santé vérifiant si PostgreSQL est démarré |
| GET | `/liveness` | Vérification de la boucle de heartbeat de Patroni (503 si dernier passage > ttl) |
| GET | `/readiness` | Vérification que PostgreSQL est démarré et ne présente pas trop de retard |

## Surveillance et Métriques

| Méthode | Point de terminaison | Description |
|---|---|---|
| GET | `/patroni` | Point de terminaison de surveillance renvoyant un JSON détaillé de l'état |
| GET | `/metrics` | Métriques au format Prometheus |

## Points de terminaison de gestion du cluster

| Méthode | Point de terminaison | Description |
|---|---|---|
| GET | `/cluster` | Topologie et état actuel du cluster (JSON) |
| GET | `/history` | Historique des basculements (switchovers/failovers) |
| GET | `/config` | Récupère la configuration dynamique actuelle |
| PATCH | `/config` | Modifie la configuration dynamique existante (mise à jour partielle) |
| PUT | `/config` | Réécrit complètement la configuration dynamique |
| POST | `/switchover` | Effectue ou planifie un basculement (switchover) |
| DELETE | `/switchover` | Supprime un basculement planifié |
| POST | `/failover` | Effectue un basculement manuel (failover) - peut entraîner des pertes de données |
| POST | `/restart` | Redémarre PostgreSQL sur ce nœud |
| DELETE | `/restart` | Supprime un redémarrage planifié |
| POST | `/reload` | Recharge la configuration de Patroni (SIGHUP) |
| POST | `/reinitialize` | Réinitialise le répertoire de données PostgreSQL |

## Valeurs d'état de PostgreSQL

Ces valeurs numériques sont utilisées dans la métrique `patroni_postgres_state`.

| Valeur | Nom de l'état | Description |
|---|---|---|
| 0 | initdb | Initialisation d'un nouveau cluster |
| 1 | initdb_failed | Échec de l'initialisation du nouveau cluster |
| 2 | custom_bootstrap | Exécution d'un script de bootstrap personnalisé |
| 3 | custom_bootstrap_failed | Échec du script de bootstrap personnalisé |
| 4 | creating_replica | Création d'un replica depuis le primaire |
| 5 | running | PostgreSQL fonctionne normalement |
| 6 | starting | PostgreSQL est en cours de démarrage |
| 7 | bootstrap_starting | Démarrage après bootstrap personnalisé |
| 8 | start_failed | Échec du démarrage de PostgreSQL |
| 9 | restarting | PostgreSQL est en cours de redémarrage |
| 10 | restart_failed | Échec du redémarrage de PostgreSQL |
| 11 | stopping | PostgreSQL est en cours d'arrêt |
| 12 | stopped | PostgreSQL est arrêté |
| 13 | stop_failed | Échec de l'arrêt de PostgreSQL |
| 14 | crashed | PostgreSQL s'est crashé |

---
Source: <https://github.com/patroni/patroni/blob/master/docs/rest_api.rst>
