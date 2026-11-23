# How-To: Back Up, Restore, and Rotate TLS Certificates

See [Scripts and CLI Reference](../../03-reference/cli-and-scripts/scripts-and-cli-reference.md) first.

## Preconditions

1. Verify `/root/.my.cnf` or `/etc/mbconfig.sh` holds valid MariaDB credentials.
2. Confirm `mariabackup` and `pigz` exist in `PATH`.
3. Confirm free disk space in `BCK_DIR` (`/data/backups/mariabackup`).

## Safety Instructions

**CAUTION:** `mbrestore.sh` stops MariaDB and replaces `DATADIR`. Disable Galera (`wsrep_on=off`) before a restore.

## Procedure

1. Create a physical Mariabackup archive:

```bash
bash scripts/bin/mbbackup.sh
```

2. List archives in `BCK_DIR`:

```bash
bash scripts/bin/mbbackup.sh -l
```

3. Restore an archive with the `.xbstream.gz` path:

```bash
bash scripts/bin/mbrestore.sh /data/backups/mariabackup/backup_<timestamp>.xbstream.gz
```

4. In `docker/mariadb/`, rotate TLS certificates without downtime:

```bash
make -C docker/mariadb renew-ssl-galera
```

## Verification Check

1. Run `sha256sum -c /data/backups/mariabackup/backup_<timestamp>.xbstream.gz.sha256sum` to verify integrity.
2. Run `mariadb -e "SHOW STATUS LIKE 'Ssl_cipher';"` to verify connections.

## Rollback

1. If restore fails, move `sav_datadir_*` back to `DATADIR` and start MariaDB.
2. If lab TLS fails, run `make -C docker/mariadb clean-ssl gen-ssl`.

Related: [Parameters and Ports](../../03-reference/configuration/automation-parameters-and-ports.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
