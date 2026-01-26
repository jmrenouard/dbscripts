# Patroni: REST API Reference

## Table of contents
- [Health Check Endpoints](#health-check-endpoints)
- [Monitoring and Metrics](#monitoring-and-metrics)
- [Cluster Management Endpoints](#cluster-management-endpoints)
- [PostgreSQL State Values](#postgresql-state-values)

> Detailed documentation of Patroni's REST API endpoints for health checks, monitoring, and cluster management.

## Health Check Endpoints

These endpoints return HTTP 200 on success and various error codes on failure.

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check for primary (leader) |
| GET | `/primary` | Health check for primary (leader) |
| GET | `/read-write` | Health check for primary (leader) |
| GET | `/standby-leader` | Health check for leader in standby cluster |
| GET | `/leader` | Health check for node with leader lock (primary or standby leader) |
| GET | `/replica` | Health check for replica (running, not primary, noloadbalance not set) |
| GET | `/read-only` | Health check for primary or replica |
| GET | `/synchronous` / `/sync` | Health check for synchronous standby |
| GET | `/read-only-sync` | Health check for primary or synchronous standby |
| GET | `/quorum` | Health check for quorum node |
| GET | `/read-only-quorum` | Health check for primary or quorum node |
| GET | `/asynchronous` / `/async` | Health check for asynchronous standby |
| GET | `/health` | Health check if PostgreSQL is running |
| GET | `/liveness` | Patroni heartbeat loop check (503 if last run > ttl) |
| GET | `/readiness` | PostgreSQL up, replicating and not too far behind leader |

## Monitoring and Metrics

| Method | Endpoint | Description |
|---|---|---|
| GET | `/patroni` | Monitoring endpoint returning detailed JSON state |
| GET | `/metrics` | Prometheus format metrics |

## Cluster Management Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/cluster` | Current cluster topology and state (JSON) |
| GET | `/history` | History of cluster switchovers/failovers |
| GET | `/config` | Get current dynamic configuration |
| PATCH | `/config` | Update dynamic configuration (partial update) |
| PUT | `/config` | Full rewrite of dynamic configuration |
| POST | `/switchover` | Perform or schedule a switchover |
| DELETE | `/switchover` | Delete currently scheduled switchover |
| POST | `/failover` | Perform manual failover (can cause data loss) |
| POST | `/restart` | Restart PostgreSQL on the node |
| DELETE | `/restart` | Delete scheduled restart |
| POST | `/reload` | Reload Patroni configuration (SIGHUP) |
| POST | `/reinitialize` | Reinitialize PostgreSQL data directory |

## PostgreSQL State Values

These numeric values are used in the `patroni_postgres_state` metric.

| Value | State Name | Description |
|---|---|---|
| 0 | initdb | Initializing new cluster |
| 1 | initdb_failed | Initialization of new cluster failed |
| 2 | custom_bootstrap | Running custom bootstrap script |
| 3 | custom_bootstrap_failed | Custom bootstrap script failed |
| 4 | creating_replica | Creating replica from primary |
| 5 | running | PostgreSQL is running normally |
| 6 | starting | PostgreSQL is starting up |
| 7 | bootstrap_starting | Starting after custom bootstrap |
| 8 | start_failed | PostgreSQL start failed |
| 9 | restarting | PostgreSQL is restarting |
| 10 | restart_failed | PostgreSQL restart failed |
| 11 | stopping | PostgreSQL is stopping |
| 12 | stopped | PostgreSQL is stopped |
| 13 | stop_failed | PostgreSQL stop failed |
| 14 | crashed | PostgreSQL has crashed |

---
Source: <https://github.com/patroni/patroni/blob/master/docs/rest_api.rst>
