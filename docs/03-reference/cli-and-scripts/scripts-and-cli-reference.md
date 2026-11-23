# Scripts and CLI Reference

`Makefile` targets, Python CLIs, shell scripts, and exit codes.

## 1. Makefile Targets

| File | Targets | Behavior |
|---|---|---|
| `Makefile` | `test` (`all`), `lint`, `clean` | Runs `unittest` (`tests`), `compileall`, removes `__pycache__`. |
| `docker/mariadb/Makefile` | `build-image`, `{up,bootstrap,down,test,check,emergency}-galera`, `test-lb-galera` | Builds `mariadb_ssh:004`, manages 3-node Galera (`NODE=1\|2\|3`). |
| `docker/mariadb/Makefile` | `{up,setup,test,check,emergency}-repli`, `{up,down}-mariadb11-repli`, `{backup,restore}-{,phys-}{galera,repli}`, `renew-ssl-{galera,repli}` | Manages `repli-legacy`/`repli-m11`, backups (`DB=`, `FILE=`), `FLUSH SSL;`. |
| `docker/mysql_replication/Makefile` | `up`, `down`, `logs`, `inject`, `mt`, `mts`, `mtf` | Compose `up -d --build --remove-orphans`, `down`, `logs -f`, `employees.sql` load, `mysqltuner.pl`. |
| `docker/script_tests/Makefile` | `build`, `test`, `test-one`, `clean` | Builds `dbscripts-script-tests:latest`, runs `scripts/` tests (`SCRIPT=`), removes image. |

## 2. Python CLIs (`docker/` & `scripts/bin/`)

| Script | Flags / Arguments | Defaults & Output |
|---|---|---|
| `docker/mysql_docker.py` | `list [--status]`, `start <env> [--db_type] [--version] [--username] [--password]`, `stop`, `rm`, `info <env> <port> --password`, `--debug` | `mysql`, `latest`, `admin`; `<env>.my.cnf` (`0600`), `mysql.bashrc`. |
| `mygenconf_mysql.py` | `--port`, `--server-id`, `--buffer-pool-size`, `--datadir` | `3306`, `1`, `2G`, `/var/lib/mysql`. |
| `mygenconf_mariadb.py` | `key=value` (`mysql_ram_gb`, `port`, `server_id`, `mysql_dir`, `max_connections`) | `1`, `3306`, `1`, `/var/lib/mysql`, `100`. |
| `mysqldump_{database,table}_splitter.py` | `dump_file` (`.sql`/`.sql.gz`) | Splits to `<dump_file>_split/`. |
| `genere_csv.py`, `generate_sql_fromcsv.py` | `--filename`, `--rows`, `--days` / `--input_file`, `--output_file`, `--separator`, `--batch_size` | `elastic_table_data.csv`/`1000000`/`60`; `;`/`10000`. |
| `tree_s3.py`, `check_tcp.py`, `findip.py` | `bucket [path] [filter] [--profile]` / `<ip> <port>` / `<file1>...` | S3 tree; TCP 3 retries/2s; `<stem>_result.csv`. |
| `show_cql_grants.py` | Env `CQLSH_PATH` / `CQLSH` | Audits `system_auth` CQL grants. |
| `scripts/build_versioned_docs.py` | `--output`, `--base-url`, `--main-ref`, `--tags`, `--skip-tags`, `--no-strict`, `--repo-root` | `site_dist`, `https://dbscripts.lightpath.fr`, `WORKTREE`. |

## 3. Shell Scripts (`scripts/`) & Exit Codes

| Script | Arguments | Behavior |
|---|---|---|
| `8_galera/{5_bootstrap_node,6_start_new_node}.sh` | `/etc/bootstrap.conf` | Writes `999_galera_settings.cnf`; `galera_new_cluster`/SST. |
| `bin/{mb,lg}{backup,restore}.sh` | `[target\|dump]`, `-l\|--list`, `-a\|--addcrontab`, `-r\|--removecrontab`, `-f\|--force` | Physical/logical backup + SHA256 restore. |
| `bin/{maria-,}pitr-restore.sh` | `<binlog_path> <date> <time>` / `[date] [time]` (`doit=1`) | GTID binlog replay / Mariabackup PITR. |
| `bin/sync_pg_databases.sh`, `ora2mariadb.sh` | `-c`, `-s`, `-t`, `-d` (`u:p@h:p`) / `./bcr_ddl.sql` | PostgreSQL sync; Oracle DDL conversion. |

Exit codes: `0` ok; `1` error/host down (`check_tcp.py`, `mbrestore.sh`, `sync_pg_databases.sh`); `2` DB down/bad flag (`lg*.sh`, `argparse`); `26` `reverse_rc(0)` (`utils.sh`); `127` missing arg/cancel (`{mb,lg}restore.sh`, `mbsetup_slave.sh`).

[Parameters & Ports](../configuration/automation-parameters-and-ports.md) | [Architecture](../../04-explanation/architecture-overview/multi-db-automation-architecture.md)
