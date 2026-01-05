# MariaDB Docker Environment 🚀

This repository provides a comprehensive MariaDB environment based on MariaDB 11.8, optimized for developing and testing complex architectures such as **Galera Cluster** and **Master/Slave Replication**.

---

## 🚀 1. Getting Started

### Build the Base Image

First, build the custom `mariadb_ssh` image containing all necessary DBA tools.

```bash
make build-image
```

### Install Client (Optional)

To interact with the databases from your host (Ubuntu/Debian), you can install the client tools:

```bash
make install-client
```

### Deploy Clusters

Choose your scenario and start the environment using Docker Compose:

#### 🌐 Galera Cluster (Multi-Master)

3 synchronous nodes with a dedicated internal network.

```bash
make up-galera
```

#### 🔄 Replication Cluster (Master/Slaves)

1 Master and 2 Slaves topology.

```bash
make up-repli
```

---

## 🛠️ 2. Makefile Usage

The `Makefile` simplifies cluster management and tool execution.

| Command | Description |
| :--- | :--- |
| `make up-galera` / `up-repli` | Start the chosen cluster |
| `make bootstrap-galera` | Bootstrap a NEW Galera cluster |
| `make down-galera` / `down-repli` | Stop and remove containers |
| `make logs-galera` / `logs-repli` | Follow cluster logs |
| `make test-galera` / `test-repli` | Run functional verification tests |
| `make test-lb-galera` | Test HAProxy Load Balancing for Galera |
| `make setup-repli` | Configure Replication topology (Master/Slaves) |
| `make backup-galera` / `backup-repli` | Perform logical backup |
| `make test-perf-galera` / `test-perf-repli` | Run performance benchmarks |
| `make gen-profiles` | Generate shell profile files with aliases |

### 🛠️ Shell Aliases (Quick Access)

To easily access MariaDB instances from your terminal without typing host and port every time:

1. Generate the profiles:

   ```bash
   make gen-profiles
   ```

2. Source the relevant profile:

   ```bash
   source profile_repli   # For Replication aliases
   # OR
   source profile_galera  # For Galera aliases
   ```

3. Use the aliases: `mariadb-m1`, `mariadb-s1`, `mariadb-g1`, `mariadb-lb`, etc.

---

## 💾 3. Backup & Restore

Dedicated scripts handle both logical (SQL) and physical (Binary) backups.

### 3.1 Logical Backup (mariadb-dump)

Compressed SQL dumps using `pigz`.

- **Galera**: `make backup-galera [DB=name]` (Stored in `/backups`)
- **Replication**: `make backup-repli [DB=name]` (Performed on a Slave)
- **Restore**: `make restore-galera FILE=xxx.sql.gz` or `make restore-repli FILE=xxx.sql.gz`

### 3.2 Physical Backup (MariaBackup)

Fast binary backups for large datasets.

- **Galera**: `make backup-phys-galera`
- **Replication**: `make backup-phys-repli`
- **Restore**: `make restore-phys-galera FILE=xxx.tar.gz` or `make restore-phys-repli FILE=xxx.tar.gz`
- **CAUTION**: Restore stops MariaDB, replaces the entire data directory, and restarts it.

---

## 🧪 4. Functional Testing

Validate cluster health and features through automated scripts.

### 4.1 Galera Cluster Testing

Verifies node connectivity, synchronous replication, DDL propagation, and conflict resolution.

```bash
make test-galera
```

### 4.2 Replication Testing

Checks Master/Slave status and verifies data consistency across all slaves.

```bash
make test-repli
```

---

## 🏎️ 5. Performance Testing (Sysbench)

Measure cluster performance and generate premium HTML reports with visual insights.

### Running Benchmarks

- **Galera**: `make test-perf-galera PROFILE=standard ACTION=run`
- **Replication**: `make test-perf-repli PROFILE=standard ACTION=run`

### Available Profiles

- `light`: Quick sanity check (1k rows)
- `standard`: Default benchmark (100k rows)
- `read`: Read-intensive workload
- `write`: Write-intensive workload

### Report Features

Detailed reports include latency charts (ms), query distribution (Read/Write/Other), and cluster-specific health stats (Galera conflicts or Replication lag).

---

## ⚙️ 6. Advanced Configuration & Access

### Persistence & Configuration

- **Data Dir**: `gdatadir_*` (Galera) or `datadir_*` (Replication)
- **Custom Config**: Edit `gcustom_X.cnf` or `custom_X.cnf` to tune InnoDB or Galera parameters.

### Access & Security

- **SSH**: User `root`, Password `rootpass`. Port mapping starts from 22001.
- **MySQL**: User `root`, Password `rootpass`.
- **Load Balancing**: HAProxy provides unified entry points.
  - Galera: `localhost:3306`
  - Replication: `localhost:3406` (Write), `localhost:3407` (Read)

---

## 📝 7. Troubleshooting

Logs are managed via Supervisor inside containers:

- `/var/log/supervisor/mariadb.err.log`

---

## 📚 8. Detailed Documentation

For more in-depth information, please refer to the **[Documentation Index](documentation/INDEX.md)** or explore the files directly:

- **[Architecture](documentation/architecture.md)**: Global topology and Mermaid diagrams.
- **[Makefile Reference](documentation/makefile.md)**: Detailed breakdown of all `make` tasks.
- **[Utility Scripts](documentation/scripts.md)**: Description of backup, SSL, and setup scripts.
- **[SSL & Replication](documentation/replication_ssl.md)**: Security configuration and verification.
- **[Galera Bootstrap](documentation/galera_bootstrap.md)**: Step-by-step guide for new clusters.
- **[Replication Setup](documentation/replication_setup.md)**: Walkthrough of the replication automation.
- **[Test Cases](documentation/tests.md)**: Automated test descriptions and expected results.
