# Patroni: Specific Monitoring

## Table of contents
- [Procedure Objective](#procedure-objective)
- [HaProxy Monitoring](#haproxy-monitoring)
- [Etcd Monitoring](#etcd-monitoring)
- [Patroni Monitoring](#patroni-monitoring)
- [PostgreSQL Monitoring](#postgresql-monitoring)
- [Replication Lag Check (SQL)](#replication-lag-check-(sql))

> This document describes the monitoring procedures for the complete HaProxy / Patroni / Etcd / PostgreSQL solution.

## Procedure Objective

Perform end-to-end monitoring of the High Availability solution to ensure database service availability.

## HaProxy Monitoring

| No. | Probe | Description |
|:---|:---|:---|
| 1 | `check_tcp` (RW Port) | Verify access to the TCP port of the HAPROXY Read/Write VIP (App-specific port). |
| 2 | `check_tcp` (RO Port) | Verify access to the TCP port of the HAPROXY Read-Only VIP (App-specific port). |
| 3 | HAProxy Process | Verify that the `/usr/sbin/haproxy` process is running. |

## Etcd Monitoring

| No. | Probe | Description |
|:---|:---|:---|
| 1 | `check_tcp` (2379) | Verify access to the Etcd client TCP port. |
| 2 | `check_tcp` (2380) | Verify access to the Etcd cluster (peer) TCP port. |
| 3 | Etcd Process | Verify that the `/usr/bin/etcd` process is running. |

## Patroni Monitoring

| No. | Probe | Description |
|:---|:---|:---|
| 1 | `check_tcp` (API) | Verify access to the Patroni client TCP port (e.g., 8008). |
| 2 | `check_url` `/health` | Verify node health via REST API. |
| 3 | `check_url` `/cluster` | Verify overall Patroni cluster health. |
| 4 | Patroni Process | Verify that the `/usr/bin/python` process (patroni daemon) is running. |

## PostgreSQL Monitoring

| No. | Probe | Description |
|:---|:---|:---|
| 1 | Standard Probes | Standard server and PostgreSQL instance monitoring (CPU, RAM, Disk, Locks). |
| 2 | WAL Receiver (Standby) | `check-pgquery`: `select count(*) from pg_stat_wal_receiver;` (must be > 0). |
| 3 | Recovery Mode (Standby) | `check-pgquery`: `select pg_is_in_recovery();` (must be `TRUE`). |
| 4 | Leader Mode (Primary) | `check-pgquery`: `select pg_is_in_recovery();` (must be `FALSE`). |
| 5 | Replications (Primary) | `select count(*) from pg_stat_replication;` (must equal expected slave count). |

### Replication Lag Check (SQL)

```sql
select pg_last_wal_receive_lsn(), 
       pg_last_wal_replay_lsn(), 
       pg_last_xact_replay_timestamp();
```

---
Source: Internal Procedures - Specific Patroni/PostgreSQL Monitoring
