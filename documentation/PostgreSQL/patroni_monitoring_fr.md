# Patroni: Supervision spécifique

## Table des matières
- [Objectif de la procédure](#objectif-de-la-procédure)
- [Monitoring HaProxy](#monitoring-haproxy)
- [Monitoring Etcd](#monitoring-etcd)
- [Monitoring Patroni](#monitoring-patroni)
- [Monitoring PostgreSQL](#monitoring-postgresql)
- [Vérification du lag de réplication (SQL)](#vérification-du-lag-de-réplication-(sql))

> Ce document décrit les procédures de supervision pour la solution complète HaProxy / Patroni / Etcd / PostgreSQL.

## Objectif de la procédure

Réaliser la supervision bout-en-bout de la solution de Haute Disponibilité pour garantir la disponibilité des services de base de données.

## Monitoring HaProxy

| N° | Sonde | Description |
|:---|:---|:---|
| 1 | `check_tcp` (Port RW) | Vérification de l'accès au port TCP de la VIP HAPROXY de lecture/écriture (Port spécifique par application). |
| 2 | `check_tcp` (Port RO) | Vérification de l'accès au port TCP de la VIP HAPROXY de lecture seule (Port spécifique par application). |
| 3 | Process HAProxy | Vérification que le processus `/usr/sbin/haproxy` est en cours d'exécution. |

## Monitoring Etcd

| N° | Sonde | Description |
|:---|:---|:---|
| 1 | `check_tcp` (2379) | Vérification de l'accès au port TCP client Etcd. |
| 2 | `check_tcp` (2380) | Vérification de l'accès au port TCP cluster (peer) Etcd. |
| 3 | Process Etcd | Vérification que le processus `/usr/bin/etcd` est en cours d'exécution. |

## Monitoring Patroni

| N° | Sonde | Description |
|:---|:---|:---|
| 1 | `check_tcp` (API) | Vérification de l'accès au port TCP client Patroni (ex: 8008). |
| 2 | `check_url` `/health` | Vérification via l'API REST de la santé du nœud. |
| 3 | `check_url` `/cluster` | Vérification de la santé globale du cluster Patroni. |
| 4 | Process Patroni | Vérification que le processus `/usr/bin/python` (démon patroni) est en cours d'exécution. |

## Monitoring PostgreSQL

| N° | Sonde | Description |
|:---|:---|:---|
| 1 | Sondes standards | Supervision standard du serveur et de l'instance PostgreSQL (CPU, RAM, Disque, Locks). |
| 2 | WAL Receiver (Standby) | `check-pgquery`: `select count(*) from pg_stat_wal_receiver;` (doit être > 0). |
| 3 | Mode Recovery (Standby) | `check-pgquery`: `select pg_is_in_recovery();` (doit être `VRAI`). |
| 4 | Mode Leader (Primaire) | `check-pgquery`: `select pg_is_in_recovery();` (doit être `FAUX`). |
| 5 | Replications (Primaire) | `select count(*) from pg_stat_replication;` (doit être égal au nombre d'esclaves attendus). |

### Vérification du lag de réplication (SQL)

```sql
select pg_last_wal_receive_lsn(), 
       pg_last_wal_replay_lsn(), 
       pg_last_xact_replay_timestamp();
```

---
Source: Procédures internes - Supervision spécifique Patroni/PostgreSQL
