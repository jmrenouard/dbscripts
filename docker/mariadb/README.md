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
| **Test** | | `make test-repli` |

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
- **Permissions**: `init-permissions.sql` grants privileges to the root user from the internal network subnet.

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
