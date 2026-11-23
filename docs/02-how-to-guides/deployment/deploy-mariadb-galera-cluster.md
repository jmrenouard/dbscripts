# How-To: Deploy a MariaDB Galera Cluster

See [Automation Parameters and Ports](../../03-reference/configuration/automation-parameters-and-ports.md) first.

## Preconditions

1. Install MariaDB Server and Galera packages on three nodes.
2. Open ports `3306`, `4444`, `4567`, and `4568`.
3. Copy `scripts/8_galera/bootstrap.conf.example` to `/etc/bootstrap.conf` on node 1.

## Safety Instructions

**CAUTION:** Back up data before `5_bootstrap_node.sh`. This script deletes Galera state files and restarts MariaDB.

## Procedure

1. Set `cluster_name`, `node_addresses`, `sst_user`, and `sst_password` in `/etc/bootstrap.conf`.
2. Export `SST_PASSWORD` if `/etc/bootstrap.conf` omits `sst_password`.
3. Bootstrap node 1:

```bash
bash scripts/8_galera/5_bootstrap_node.sh
```

4. Wait until node 1 reaches `Synced` and copies `/etc/bootstrap.conf`.
5. Join node 2 and node 3:

```bash
bash scripts/8_galera/6_start_new_node.sh
```

## Verification Check

1. Query status on node 1:

```bash
mariadb -Nrs -e "SHOW GLOBAL STATUS WHERE Variable_name IN ('wsrep_cluster_size','wsrep_local_state_comment','wsrep_ready');"
```

2. Confirm `wsrep_cluster_size` is `3`, `wsrep_local_state_comment` is `Synced`, and `wsrep_ready` is `ON`.

## Rollback

1. Run `bash scripts/8_galera/5b_disable_galera.sh` on each node to disable `999_galera_settings.cnf` and restart MariaDB.

Related: [Scripts and CLI Reference](../../03-reference/cli-and-scripts/scripts-and-cli-reference.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
