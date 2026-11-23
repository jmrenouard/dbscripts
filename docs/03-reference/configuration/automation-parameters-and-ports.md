# Automation Parameters and Ports

Environment variables, config files, and multi-DB ports.

## 1. Environment Variables

| Variable | Default | Component | Purpose |
|---|---|---|---|
| `PYTHON` | `python` | `Makefile` | `test`, `lint`, `clean` binary. |
| `SST_PASSWORD`, `MARIADB_GALERA_BOOTSTRAP` | empty, `0` | `5_bootstrap_node.sh`, `docker-compose-galera.yml` | SST auth; primary bootstrap (`1`). |
| `NODE` | `1` | `docker/mariadb/Makefile` | Node `1\|2\|3`. |
| `DB_TYPE`, `DB_VERSION`, `DB_NAME`, `ROOT_PASSWORD` | `mariadb`/`11.4`/`testdb`/`secret` | `docker-compose-repli.yml`, `.env_example` | Image, schema, pass (`mysql`/`5.7`/`mydb`). |
| `REPL_USER`, `REPL_PASSWORD` | `repl`, `replpass` | `.env_example`, `mariadb11-repli.env_example` | Replication credentials. |
| `BCK_DIR`, `TMP_DIR`, `DATADIR` | `/data/backups/{mariabackup,logical}`, `/data/backups/tmp`, `/var/lib/mysql` | `mb*.sh`, `lg*.sh` | Backup, staging, data paths. |
| `KEEP_LAST_N_BACKUPS`, `GZIP_CMD` | `5`, `pigz` | `mb*.sh`, `lg*.sh`, `pitr-*.sh` | Retention and compressor. |
| `CQLSH_PATH`, `CQLSH` | `cqlsh` | `show_cql_grants.py` | Cassandra `cqlsh` binary. |
| `DBSCRIPTS_DOCS_REF`, `DBSCRIPTS_DOCS_SITE_URL` | `main`, `https://dbscripts.lightpath.fr` | `scripts/mkdocs_hooks.py` | Git ref and site URL. |

## 2. Config Files & Multi-DB Ports

| Path | Format | Role |
|---|---|---|
| `/etc/bootstrap.conf` | Shell vars | `cluster_name`, `node_addresses`, `sst_user`, `sst_password`, `DB_VERSION`. |
| `/etc/my.cnf.d/999_galera_settings.cnf` | INI | Galera config (`/etc/mysql/conf.d/` or `mariadb.conf.d/`). |
| `/etc/{mb,lg}config*.sh`, `<env>.my.cnf` | Shell / INI (`0600`) | Backup overrides; `mysql_docker.py` client config. |
| `docker/mariadb/haproxy-{galera,repli}.cfg` | HAProxy | Galera `3306`; Repli `3306` (W), `3307` (R); stats `8404`. |

| Component | Protocol | Port | Purpose |
|---|---|---|---|
| MariaDB / MySQL | TCP | `3306`, `3511..3513`, `3406..3407`, `3411..3413`, `3307..3309` | SQL, Galera, HAProxy, replicas. |
| SSH & HAProxy | TCP/HTTP | `22001`, `24002..24003`, `23001..23003`, `8404`, `8405`, `3310`, `9200` | Lab SSH, stats, `clustercheck`. |
| Galera / GR | TCP/UDP | `4567`, `4568`, `4444`, `33061` | WSREP, IST, SST, MySQL GCS. |
| ProxySQL / MaxScale | TCP | `6033`, `6032`, `6080`, `4006`, `4008` | ProxySQL and MaxScale ports. |
| PostgreSQL / Cassandra | TCP | `5432`, `9042` | PostgreSQL K8s; Cassandra CQL. |
| Monitoring & UI | TCP | `9090`, `3000`, `8081`, `10050`, `5666` | Prometheus, Grafana, Semaphore, Zabbix, NRPE. |

[Scripts & CLI](../cli-and-scripts/scripts-and-cli-reference.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
