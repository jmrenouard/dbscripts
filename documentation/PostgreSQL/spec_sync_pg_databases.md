# Specification: PostgreSQL Multi-Database Synchronization and Audit

Technical specification for [`scripts/bin/sync_pg_databases.sh`](../../scripts/bin/sync_pg_databases.sh), a Bash pipeline that migrates, synchronizes, optimizes, and audits PostgreSQL databases from a source instance to a target instance.

## 1. Overview and Requirements

- **Script Path**: `scripts/bin/sync_pg_databases.sh`
- **Shell Safety**: Runs with `#!/bin/bash` and `set -euo pipefail`.
- **Required Binaries**: `psql`, `pg_dump`, `pg_dumpall`, `comm`, and `diff` (verified at startup by `check_dependencies`; exits with code `1` if any binary is missing).
- **Zero Intermediate Data Dumps**: Roles, schemas, and table data stream directly from `pg_dumpall` / `pg_dump` to `psql` over shell pipes.

## 2. Command-Line Options and Configuration

The script performs a two-pass argument parse over `ORIGINAL_ARGS` so CLI options always override configuration file defaults:

1. **Pass 1 (`-c` / `--config`)**: Sources the specified `.env` configuration file if present; exits with code `1` if missing.
2. **Pass 2 (`-s`, `-t`, `-d`)**: Overrides source, target, and database settings from CLI flags; exits with code `1` on invalid connection formats or unknown flags.

| Option | Argument Format | Description |
| :--- | :--- | :--- |
| `-c`, `--config` | `<path>` | Optional environment file sourced at startup (e.g., `config.env`). |
| `-s`, `--source` | `user:pass@host:port` | Overrides `SRC_USER`, `SRC_PASS`, `SRC_HOST`, and `SRC_PORT`. |
| `-t`, `--target` | `user:pass@host:port` | Overrides `TGT_USER`, `TGT_PASS`, `TGT_HOST`, and `TGT_PORT`. |
| `-d`, `--database` | `<dbname>` | Targets a single database (`TARGET_DB`). If omitted, processes all non-template source databases except `postgres` and `rdsadmin`. |

### Configuration Variables (`config.env`)

Credentials are supplied via environment variables and passed inline via `PGPASSWORD` (masked as `PGPASSWORD='***'` in command logs):

```dotenv
# Source PostgreSQL instance
SRC_HOST=10.0.0.10
SRC_PORT=5432
SRC_USER=postgres_admin_src
SRC_PASS=<SOURCE_PASSWORD>

# Target PostgreSQL instance
TGT_HOST=10.0.0.20
TGT_PORT=5432
TGT_USER=postgres_admin_tgt
TGT_PASS=<TARGET_PASSWORD>

# Optional single target database (leave empty to sync all user databases)
TARGET_DB=my_production_db
```

## 3. Six-Stage Synchronization Pipeline

| Stage | Action | PostgreSQL Implementation |
| :--- | :--- | :--- |
| **1** | **Role Synchronization** | Queries non-system roles (`rolname NOT LIKE 'pg_%'`) on source and target, diffs via `comm -23`, and pipes missing roles through `pg_dumpall -r \| psql -d postgres -q` with `set +e +o pipefail` so pre-existing partial roles warn without aborting. |
| **2** | **Schema Migration** | Creates missing target databases (`CREATE DATABASE "<db>";`) and streams DDL via `pg_dump -s -d "$db" \| psql -d "$db" -q`. |
| **3** | **Data Migration** | Streams table data with triggers disabled via `pg_dump -a --disable-triggers -d "$db" \| psql -d "$db" -q`. |
| **4** | **Ownership Alignment** | Queries each target database owner (`pg_get_userbyid(datdba)`) and dynamically pipes `ALTER SCHEMA`, `ALTER TABLE`, `ALTER VIEW`, and `ALTER SEQUENCE ... OWNER TO` statements for all non-system objects (`pg_%` and `information_schema` excluded). |
| **5** | **Optimization** | Runs `VACUUM ANALYZE;` via `psql` on each migrated target database. |
| **6** | **Audit and Validation** | Compares per-table row counts (`SELECT count(*)`) between source and target, and diffs source vs. target `pg_dump -s` DDL via `diff -u` (retaining `/tmp/diff_schema_<db>.patch` only on mismatch). |

## 4. Logging, Timers, and Exit Status

- **Step Banners and Timers**: `start_step` and `end_step` log start/end banners with emoji status markers and per-step duration in seconds.
- **Credential Masking**: Logged command previews replace passwords with `PGPASSWORD='***'`.
- **Final Summary**: Prints a summary table showing step number, title, duration, step status, and total runtime (`GLOBAL_DUR`), exiting with code `1` if any step failed.
