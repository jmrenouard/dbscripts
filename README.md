# Database Scripts Automation (`dbscripts`)

[![Test Suite](https://img.shields.io/badge/tests-49%20passed-brightgreen.svg)](tests/)
[![Python](https://img.shields.io/badge/python-3.9%2B-blue.svg)](Makefile)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Governance](https://img.shields.io/badge/governance-strict%20registers-orange.svg)](docs/ACTION_LOGBOOK.md)

Robust, reproducible automation solutions for multi-vendor enterprise database infrastructures across **MariaDB/Galera**, **MySQL**, **PostgreSQL**, **MongoDB**, **Cassandra**, and **Oracle**.

---

## 🏛️ Repository Architecture

| Directory | Scope & Description |
|---|---|
| [`scripts/`](scripts/) | Shell & Python scripts for OS hardening, DBMS setup, clustering, backups, and CLI tools. |
| [`ansible/`](ansible/) | Ansible playbooks and roles for InnoDB Cluster, OS upgrades, and Redis ACL management. |
| [`docker/`](docker/) | Multi-container labs: 3-node Galera cluster, MySQL replication, PostgreSQL sandboxes. |
| [`sql/`](sql/) | Diagnostic queries, Performance Schema analysis, maintenance routines, security audits. |
| [`documentation/`](documentation/) | Technical operational guides in English for Galera, Patroni, MongoDB, and Linux tuning. |
| [`docs/`](docs/) | Living governance registers: [`ACTION_LOGBOOK.md`](docs/ACTION_LOGBOOK.md) and [`RCA_REGISTER.md`](docs/RCA_REGISTER.md). |
| [`tests/`](tests/) | Automated unit tests (49 tests) verifying shell scripts, Ansible, and Python CLIs. |

---

## 🚀 Multi-DBMS Automation Matrix

| DBMS Platform | Key Entry Point | Usage Description |
|---|---|---|
| **MariaDB Galera** | `scripts/8_galera/5_bootstrap_node.sh` | Bootstrap primary Galera cluster node. |
| **MariaDB Galera** | `scripts/8_galera/6_start_new_node.sh` | Connect node to active Galera cluster (SST). |
| **MariaDB Backup** | `scripts/bin/mbbackup.sh` | Physical full/incremental backups with Mariabackup. |
| **MariaDB Restore**| `scripts/bin/mbrestore.sh` | Prepare and restore Mariabackup archives to datadir. |
| **MySQL Docker**   | `docker/mysql_docker.py` | CLI to manage multi-container MySQL sandboxes. |
| **MySQL Cluster**  | `ansible/playbook_innodb_cluster_group.yml` | Deploy MySQL InnoDB Cluster with Group Replication. |
| **MySQL Tools**    | `scripts/bin/mysqldump_database_splitter.py` | Split large mysqldump archives by database. |
| **PostgreSQL**     | `scripts/7_postgres/1a_install_postgres_centos.sh` | Install & initialize PostgreSQL on RHEL/CentOS. |
| **PostgreSQL**     | `scripts/7_postgres/4_setup_slave_config.sh` | Configure streaming replication standby nodes. |
| **MongoDB**        | `scripts/1_system/9_mongodb_system.sh` | Tune kernel limits, disable THP, configure swap. |
| **Cassandra**      | `cassandra/show_cql_grants.py` | Audit & export CQL permissions on keyspaces/tables. |
| **Oracle**         | `oracle/ora2mariadb.sh` | Convert Oracle DDL definitions to MariaDB format. |

---

## 🧪 Laboratory & Quickstart

### MariaDB Galera Cluster Lab (3 Nodes + HAProxy)
```bash
cd docker/mariadb
make galera-up       # Launch 3 Galera nodes and HAProxy
make test-galera     # Run cluster replication tests
make galera-down     # Teardown containers and clean state
```

### PostgreSQL Miniapp Sandbox
```bash
docker compose -f docker/miniapps/postgresql/docker-compose.yml up -d
```

### MySQL Container Manager CLI
```bash
python docker/mysql_docker.py run --name mysql-lab --port 3306 --version 8.0
python docker/mysql_docker.py status
```

---

## ✅ Testing & Quality Assurance

All shell scripts, Ansible YAML files, Python utilities, and governance rules are continuously verified:

```bash
# Run the complete unit test suite (49 unit tests)
make test
# or directly:
python -m unittest discover -s tests -v

# Run Python compilation check across modules
make lint
```

---

## 📜 Governance & Workflow

This project adheres strictly to the GitHub lifecycle and living governance registers:
- Every contribution requires a dedicated issue, branch, validated tests, and atomic PR.
- All Pull Requests must remain strictly under **15,000 characters** in diff size.
- Updates must be logged in [`docs/ACTION_LOGBOOK.md`](docs/ACTION_LOGBOOK.md) and [`docs/RCA_REGISTER.md`](docs/RCA_REGISTER.md).
