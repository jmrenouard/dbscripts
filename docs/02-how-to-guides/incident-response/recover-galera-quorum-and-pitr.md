# Runbook: Recover Galera Quorum and Replay Binlog PITR

See [Database Alert and Error Matrix](../../03-reference/troubleshooting-codes/database-alert-and-error-matrix.md) first.

## Preconditions

1. Confirm SSH access on all database hosts.
2. Locate the node with highest `seqno` in `/var/lib/mysql/grastate.dat`.
3. Confirm binary log files exist for point-in-time recovery.

## Safety Instructions

**WARNING:** Never bootstrap two Galera nodes at once. Concurrent bootstraps cause split-brain divergence.

**CAUTION:** Replay binary logs only on an isolated host or after a full backup.

## Procedure

1. Stop MariaDB on all nodes:

```bash
systemctl stop mariadb
```

2. Set `safe_to_bootstrap: 1` in `/var/lib/mysql/grastate.dat` on the highest `seqno` node.
3. Bootstrap the primary node (or `make -C docker/mariadb emergency-galera NODE=1` in lab):

```bash
galera_new_cluster
```

4. Start MariaDB on peer nodes to rejoin via IST or SST.
5. For GTID PITR, replay binary logs to the stop timestamp:

```bash
bash scripts/bin/maria-pitr-restore.sh /var/log/mysql 2026-11-23 12:00:00
```

## Verification Check

1. Run `mariadb -Nrs -e "SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size';"` and confirm all nodes join.
2. Inspect `/var/log/mysql/mysqld.log` for errors.

## Rollback

1. If a peer fails to join, run `bash scripts/8_galera/10_reset_galera_node.sh` and restart MariaDB.

Related: [Alert Matrix](../../03-reference/troubleshooting-codes/database-alert-and-error-matrix.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
