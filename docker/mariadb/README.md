# MariaDB Docker Environment 🚀

This directory contains a complete MariaDB environment based on MariaDB 11.8, designed for development and testing of complex architectures like **Galera Cluster** and **Master/Slave Replication**.

## 🏗️ Architecture & Features

The environment is built around a custom Docker image (`mariadb_ssh`) which includes:

- **MariaDB 11.8**: The core database engine.
- **SSH Access**: Pre-configured SSH server for remote management and troubleshooting.
- **Supervisor**: Manages both SSH and MariaDB processes within the same container.
- **DBA Tools**: Includes `percona-toolkit`, `sysbench`, `vim`, `nano`, `htop`, `iotop`, `net-tools`, `pigz`, `wget`, `curl`, `git`.
- **Custom Scripts**: `start-mariadb.sh` handles initial database creation and permissions.

---

## 🛠️ Getting Started

### 1. Build the Base Image

First, you need to build the custom image. You can use the Makefile for convenience:

```bash
make build-image
# or manually
docker build -t mariadb_ssh:004 .
```

### 2. Manage Clusters with Makefile 🚀

A `Makefile` is provided to simplify management and log access:

| Action | Galera Cluster | Replication Cluster |
| :--- | :--- | :--- |
| **Start** | `make up-galera` | `make up-repli` |
| **Stop** | `make down-galera` | `make down-repli` |
| **Logs** | `make logs-galera` | `make logs-repli` |
| **Test** | `make test-galera` | `make test-repli` |

Use `make help` to see all available commands.

---

## 🏗️ Deployment Scenarios

### A. 🌐 Galera Cluster (Multi-Master)

This setup uses 3 nodes in a synchronous replication cluster.

- **Config file**: `docker-compose-galera.yml`
- **Starting**: `docker-compose -f docker-compose-galera.yml up -d`
- **Network**: `10.6.0.0/24`
- **Nodes**:
  - `galera_01` (10.6.0.11), Port 3511
  - `galera_02` (10.6.0.12), Port 3512
  - `galera_03` (10.6.0.13), Port 3513

### B. 🔄 Classic Replication (Master/Slaves)

This setup uses 3 nodes to simulate a standard replication topology.

- **Config file**: `docker-compose-repli.yml`
- **Starting**: `docker-compose -f docker-compose-repli.yml up -d`
- **Network**: `10.5.0.0/24`
- **Nodes**:
  - `mariadb_01` (Master - 10.5.0.11), Port 3411
  - `mariadb_02` (Slave - 10.5.0.12), Port 3412
  - `mariadb_03` (Slave - 10.5.0.13), Port 3413

---

## ⚙️ Special Configuration

### Configuration Files (`.cnf`)

Each node can have its own custom configuration via files named `custom_X.cnf` (for replication) or `gcustom_X.cnf` (for galera). These are mounted to `/etc/mysql/mariadb.conf.d/999_custom.cnf` as read-only.

### Persistence

Data is persisted in local directories:

- Galera: `gdatadir_01`, `gdatadir_02`, `gdatadir_03`
- Replication: `datadir_01`, `datadir_02`, `datadir_03`

Backups are stored in:

- Galera: `gbackups_01`, `gbackups_02`, `gbackups_03`
- Replication: `backups_01`, `backups_02`, `backups_03`

---

## 🔐 Security & Access

### SSH Access

- **User**: `root`
- **Password**: `rootpass` (Configured in Dockerfile)
- **SSH Keys**: The image automatically includes the provided `id_rsa.pub` in `/root/.ssh/authorized_keys`.
- **Ports**:
  - Galera: 22001, 24002, 24003
  - Replication: 23001, 23002, 23003

### MySQL Access

- **User**: `root`
- **Password**: `rootpass` (Defined in environment variables)
- **Permissions**: `init-permissions.sql` grants privileges to the root user from the internal network subnet. It also configures `repli_user` for standard replication and `sst_user` for Galera SST.

 ---

## ⚖️ Load Balancing (HAProxy)

 Each cluster includes an HAProxy container to provide a unified entry point and load balancing.

### 🌐 Galera Cluster (HAProxy)

- **Entry Point**: `localhost:3306` (Round-robins to all 3 nodes)
- **Stats Page**: `http://localhost:8404/stats`

### 🔄 Replication Cluster (HAProxy)

- **Write Point (Master)**: `localhost:3406` (Points to Node 1)
- **Read Point (Slaves)**: `localhost:3407` (Round-robins between Nodes 2 & 3)
- **Stats Page**: `http://localhost:8405/stats`

---

## 📝 Troubleshooting & Logs

Since processes are managed via Supervisor, you can check logs inside the container:

- `/var/log/supervisor/mariadb.err.log`
- `/var/log/supervisor/sshd.err.log`
- `/var/log/supervisor/supervisord.log`

## 🧪 Testing Replication

You can automatically verify that the Master/Slave replication is working correctly using:

```bash
make test-repli
```

This script will:

1. Check if all 3 nodes are online.
2. Display Master and Slave status.
3. Create a test database/table on the master.
4. Verify that data is correctly replicated to both slaves.

## 🏎️ Performance Testing (Sysbench)

You can benchmark both clusters using the `test_perf.sh` script, which provides multiple testing profiles.

### Usage

 ```bash
 ### 🏎️ Performance Benchmarking (sysbench)

Des scripts dédiés permettent de mesurer les performances de chaque architecture :

#### 🔹 Tester Galera (Optimistic Locking & Conflits)
```bash
# Préparation des données (1 table de 100k lignes par défaut en profil standard)
make test-perf-galera PROFILE=light ACTION=prepare

# Exécution du benchmark
make test-perf-galera PROFILE=light ACTION=run
```

Génère un rapport détaillé : `test_perf_galera.html`.

#### 🔹 Tester Replication (Master/Slave Lag & Read Scale)

```bash
# Préparation des données
make test-perf-repli PROFILE=light ACTION=prepare

# Exécution du benchmark
make test-perf-repli PROFILE=light ACTION=run
```

Génère un rapport détaillé : `test_perf_repli.html`.

> [!TIP]
> Chaque exécution génère un rapport visuel premium utilisant Tailwind CSS et Chart.js pour faciliter l'audit des performances.

### Profiles

| Profile | Description |
| :--- | :--- |
| **light** | 5 tables, 1,000 rows (Quick sanity check) |
| **standard** | 10 tables, 10,000 rows (Default benchmark) |
| **read** | Read-only intensive benchmark |
| **write** | Write-only intensive benchmark |

### Targets

- **galera**: Targets the Galera Cluster via HAProxy (`localhost:3306`).
- **repli**: Targets the Replication Cluster via HAProxy (`localhost:3406`).

---

## 🧪 Testing Galera Cluster

 You can automatically verify that the Galera Cluster is working correctly using:

 ```bash
 make test-galera
 ```

 This script performs a comprehensive suite of tests:

 1. **Connectivity & Status**: Checks if all 3 nodes are online, ready (`wsrep_ready`), and part of a primary cluster of size 3.
 2. **Synchronous Replication**: Verifies that data inserted on one node is immediately available on all others.
 3. **Auto-increment Consistency**: Ensures that the cluster correctly manages non-conflicting auto-increment IDs across multiple masters.
 4. **Certification Conflict (Optimistic Locking)**: Simulates concurrent updates on the same record to verify Galera's conflict resolution.
 5. **DDL Replication**: Verifies that schema changes (`ALTER TABLE`) are propagated synchronously across the cluster.
 6. **Unique Key Constraints**: Checks that duplicate keys are rejected globally across all nodes.
 7. **Cluster Summary**: Displays technical details like `wsrep_incoming_addresses` and auto-increment variables.
