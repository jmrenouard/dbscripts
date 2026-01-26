# Patroni : Cas de tests de comportement HA

## Table des matières
- [Objectif de la procédure](#objectif-de-la-procédure)
- [Analyse des logs /var/log/patroni/patroni.log](#analyse-des-logs-/var/log/patroni/patroni.log)
- [Tests sur un serveur Standby (Arrêt/Reboot/Kill)](#tests-sur-un-serveur-standby-(arrêt/reboot/kill))
- [Tests sur un serveur Primaire (Arrêt/Reboot/Kill)](#tests-sur-un-serveur-primaire-(arrêt/reboot/kill))
- [Tests isolation de nœud Standby (Blocage TCP)](#tests-isolation-de-nœud-standby-(blocage-tcp))
- [Tests isolation de nœud Primaire (Blocage TCP)](#tests-isolation-de-nœud-primaire-(blocage-tcp))

> Ce document décrit les procédures de test pour valider le comportement Haute Disponibilité (HA) d'un cluster PostgreSQL piloté par Patroni.

## Objectif de la procédure

Réaliser les tests d'utilisation et de résilience de la plateforme Patroni/PostgreSQL dans différents scénarios de défaillance.

## Analyse des logs /var/log/patroni/patroni.log

Un point important est l'apparition d'une *stack trace* Python lorsque les serveurs HaProxy testent l'URL `/read-write` sur les nœuds standby (non leader). Cela est normal et indique une déconnexion brutale du client.

**Exemple de log :**

```text
2026-01-26 14:02:35,835 WARNING: Traceback (most recent call last):
  File "/usr/lib64/python3.9/socketserver.py", line 654, in process_request_thread
    self.finish_request(request, client_address)
  ...
ConnectionResetError: [Errno 104] Connection reset by peer
```

## Tests sur un serveur Standby (Arrêt/Reboot/Kill)

| ID | Scénario de test | Commandes | Observations |
|:---|:---|:---|:---|
| 1 | Tuer le processus PostgreSQL | `ps -edf\|grep '[/]usr/pgsql-16/bin/postgres' \| awk '{ print $2}' \| xargs kill -9` | Patroni relance le serveur PostgreSQL automatiquement. Le service reste opérationnel. |
| 2 | Arrêt du serveur PostgreSQL | `pg_ctl stop -D /var/lib/pgsql/data` | Patroni relance le serveur PostgreSQL automatiquement. |
| 3 | Reboot du serveur Linux | `# reboot` | Si Patroni est en `enable`, il redémarre PostgreSQL au boot. Pas de perte de service globale. |
| 4 | Arrêt du service Patroni | `# systemctl stop patroni` | Le serveur PostgreSQL est arrêté en même temps. Pas de bascule (failover) car le primaire est sain. |

## Tests sur un serveur Primaire (Arrêt/Reboot/Kill)

| ID | Scénario de test | Commandes | Observations |
|:---|:---|:---|:---|
| 1 | Tuer le processus PostgreSQL | `kill -9 <PID_POSTGRES>` | Patroni relance PostgreSQL. Le serveur reste Primaire. Pas de failover car le démon Patroni est toujours actif. |
| 2 | Arrêt du serveur PostgreSQL | `pg_ctl stop -D /var/lib/pgsql/data` | Patroni relance PostgreSQL automatiquement. Le nœud reste Primaire. |
| 3 | Reboot du serveur Linux | `# reboot` | Un nœud standby est réélu Primaire. Le service est maintenu par le nouveau leader. |
| 4 | Arrêt du service Patroni | `# systemctl stop patroni` | PostgreSQL est arrêté. Un autre nœud est automatiquement élu Primaire. Continuité de service assurée. |
| 5 | Arrêt de 2 serveurs Patroni | (Arrêt sur Standby + Primaire) | La bascule automatique fonctionne. Le dernier serveur opérationnel reste actif. |

## Tests isolation de nœud Standby (Blocage TCP)

| ID | Scénario de test | Commandes | Observations |
|:---|:---|:---|:---|
| 1 | Isoler port PG (5432) - DROP | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Le serveur disparaît de `patronictl list`. Blacklisté par le Load Balancer. |
| 1B | Tentative de switchover | `patronictl switchover` | Les opérations de switchover depuis les autres nœuds fonctionnent normalement. |
| 1C | Déverrouillage | `iptables --flush` | Retour à la normale après quelques minutes pour rejoindre le cluster. |
| 2 | Isoler port Patroni (8008) - DROP | `iptables -A INPUT -p tcp --dport 8008 -j DROP` | Blacklisté par HAProxy. `patronictl list` ne détecte pas immédiatement la perte. |
| 2B | Bascule vers serveur bloqué | `patronictl switchover --candidate=node_isole` | Échec de la bascule (Code 412) : pas de candidat valide trouvé. |
| 2C | Bascule vers serveur sain | `patronictl switchover --candidate=node_sain` | La bascule fonctionne. Le nœud isolé est marqué en `stopped/unknown`. |
| 3 | Isoler port PG (5432) - REJECT | `iptables -A INPUT -p tcp --dport 5432 -j REJECT` | Comportement similaire au DROP. Détection après quelques minutes. |
| 4 | Isoler port Patroni (8008) - REJECT | `iptables -A INPUT -p tcp --dport 8008 -j REJECT` | Comportement similaire au DROP. Bascule vers nœud sain possible. |

## Tests isolation de nœud Primaire (Blocage TCP)

| ID | Scénario de test | Commandes | Observations |
|:---|:---|:---|:---|
| 1 | Isoler port PG (5432) - DROP | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Perte du leader. Une réélection est déclenchée. Nouveau leader promu. |
| 5 | Isoler port PG (5432) sur Primaire | `iptables -A INPUT -p tcp --dport 5432 -j DROP` | Les processus ne s'arrêtent pas, mais l'API ne répond plus. Nouveau leader élu après expiration du TTL. |
| 6 | Isoler port Patroni (8008) sur Primaire | `iptables -A INPUT -p tcp --dport 8008 -j DROP` | **Attention** : Pas de bascule automatique immédiate car Patroni ne se voit pas défaillant ! |
| 7 | Isoler port PG (5432) - REJECT | `iptables -A INPUT -p tcp --dport 5432 -j REJECT` | Nouveau leader réélu suite à l'impossibilité d'accéder à PostgreSQL. |
| 8 | Isoler port Patroni (8008) - REJECT | `iptables -A INPUT -p tcp --dport 8008 -j REJECT` | Pas de bascule automatique du leader. Isolation au niveau Proxy uniquement. |

---
Source: Procédures internes - Tests de comportements HA PostgreSQL/Patroni
