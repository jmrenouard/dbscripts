# Utility Scripts Documentation 📜

This document describes the various shell scripts available in the `docker/mariadb` directory for managing the MariaDB environment.

## 💾 Backup & Restore

### Logical Backup (`mariadb-dump`)

- **[backup_logical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/backup_logical.sh)**: Performs a compressed SQL dump.
  - Usage: `./backup_logical.sh <galera|repli> [database_name]`
  - Features: Uses `pigz` for fast compression, includes routines, triggers, and events.
- **[restore_logical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/restore_logical.sh)**: Restores a logical backup.
  - Usage: `./restore_logical.sh <galera|repli> <filename.sql.gz>`

### Physical Backup (MariaBackup)

- **[backup_physical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/backup_physical.sh)**: Performs a hot physical backup using MariaBackup.
  - Usage: `./backup_physical.sh <galera|repli>`
  - Features: Creates a consistent snapshot without locking the database.
- **[restore_physical.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/restore_physical.sh)**: Restores a physical backup.
  - Usage: `./restore_physical.sh <galera|repli> <filename.tar.gz>`
  - **CAUTION**: This script stops MariaDB, replaces the entire data directory, and restarts it.

## 🔐 Security & SSL

- **[gen_ssl.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/gen_ssl.sh)**: Generates a complete SSL certificate chain (CA, Server, and Client).
  - Outputs are stored in the `ssl/` directory.
  - Certificates are automatically used by containers via volume mounts.

## ⚙️ Configuration & Setup

- **[setup_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/setup_repli.sh)**: Automates the Master/Slave replication setup.
  - Performs initial data sync from Master to Slaves.
  - Sets up GTID-based replication.
- **[gen_profiles.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/gen_profiles.sh)**: Generates `profile_galera` and `profile_repli`.
  - Provides shell aliases (e.g., `mariadb-m1`, `mariadb-g1`) for quick access to containers.

## 🧪 Testing

- **[test_galera.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_galera.sh)**: Full suite for Galera (sync, DDL, conflicts).
- **[test_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_repli.sh)**: Verification for Master/Slave replication.
- **[test_perf_galera.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_perf_galera.sh)** / **[test_perf_repli.sh](file:///home/jmren/win_home/Documents/dbscripts/docker/mariadb/test_perf_repli.sh)**: Performance benchmarks using Sysbench.
