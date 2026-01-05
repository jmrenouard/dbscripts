# Makefile Reference 🛠️

The `Makefile` is the main entry point for managing both Galera and Replication clusters.

## 🛠️ Global Commands

| Command | Description |
| :--- | :--- |
| `make help` | Show help message for all available tasks. |
| `make build-image` | Build the base `mariadb_ssh:004` image. |
| `make install-client` | Install MariaDB client on the host (Ubuntu/Debian). |
| `make gen-ssl` | Generate SSL certificates in `ssl/` directory. |
| `make clean-ssl` | Remove generated certificates. |
| `make gen-profiles` | Generate shell profiles for quick container access. |
| `make clean-data` | **DANGER**: Remove all data and backup directories. |

## 🌐 Galera Cluster Commands

| Command | Description |
| :--- | :--- |
| `make up-galera` | Start the Galera cluster nodes and HAProxy. |
| `make bootstrap-galera`| Sequentially bootstrap a new cluster (ensures node 1 is primary). |
| `make down-galera` | Stop and remove the Galera cluster. |
| `make logs-galera` | View real-time logs for the Galera cluster. |
| `make test-galera` | Run the Galera functional test suite. |
| `make test-lb-galera` | Specifically test the HAProxy load balancer for Galera. |
| `make backup-galera` | Perform a logical SQL backup. |
| `make test-perf-galera`| Run Sysbench benchmarks (Usage: `make test-perf-galera PROFILE=light ACTION=run`). |

## 🔄 Replication Cluster Commands

| Command | Description |
| :--- | :--- |
| `make up-repli` | Start the Replication cluster nodes and HAProxy. |
| `make setup-repli` | Configure Master/Slave relationship and initial sync. |
| `make down-repli` | Stop and remove the Replication cluster. |
| `make logs-repli` | View real-time logs for the Replication cluster. |
| `make test-repli` | Run the Replication functional test suite. |
| `make backup-repli` | Perform a logical SQL backup (on a slave). |
| `make test-perf-repli` | Run Sysbench benchmarks (Usage: `make test-perf-repli PROFILE=light ACTION=run`). |
