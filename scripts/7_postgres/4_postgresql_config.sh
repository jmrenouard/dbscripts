#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"13"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: $_NAME"



echo "ALTER SYSTEM RESET ALL;
ALTER SYSTEM SET listen_addresses = '*';

CREATE EXTENSION IF NOT EXISTS \"pg_stat_statements\";
CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

ALTER SYSTEM SET log_min_duration_statement = '3000';
ALTER SYSTEM SET log_checkpoints = 'on';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM SET log_duration = 'on';
ALTER SYSTEM SET log_hostname = 'on';
ALTER SYSTEM SET log_error_verbosity = 'default';
ALTER SYSTEM SET  log_line_prefix = '%m [%p] %q%u@%d '
-- ALTER SYSTEM SET log_line_prefix = '%m [%p]:%e [%l-1] user=%u,db=%d,host=%h,app=%a';
ALTER SYSTEM SET log_lock_waits = 'on';
ALTER SYSTEM SET log_temp_files = 0;
ALTER SYSTEM SET log_autovacuum_min_duration = '0';

ALTER SYSTEM SET archive_mode = off;
ALTER SYSTEM SET archive_command = 'pigz < %p > /archives/{{ TARGET_INSTANCE }}/%f.gz';
ALTER SYSTEM SET archive_timeout = 3600;

ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_wal_size='1GB';
-- ALTER SYSTEM SET wal_keep_segments = 10;

ALTER SYSTEM SET seq_page_cost = 1;
ALTER SYSTEM SET random_page_cost = 1;
ALTER SYSTEM SET effective_io_concurrency = 5;

ALTER SYSTEM SET max_worker_processes = 8;

ALTER SYSTEM SET max_logical_replication_workers = 4;
ALTER SYSTEM SET max_sync_workers_per_subscription = 2;

ALTER SYSTEM SET fsync = on;
ALTER SYSTEM SET synchronous_commit = on;
ALTER SYSTEM SET full_page_writes = on;

ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET pg_stat_statements.track = 'all';

ALTER SYSTEM SET log_filename = 'postgresql.log';
ALTER SYSTEM SET log_truncate_on_rotation=on;
ALTER SYSTEM SET log_rotation_size = '1GB';
" |su - postgres -c "psql -Upostgres"


echo "DROP ROLE IF EXISTS replication;
CREATE ROLE replication;
ALTER ROLE replication WITH SUPERUSER NOINHERIT NOCREATEROLE NOCREATEDB LOGIN REPLICATION NOBYPASSRLS PASSWORD 'replication1234' VALID UNTIL 'infinity';

DROP ROLE IF EXISTS monitoring;
CREATE ROLE monitoring;
ALTER ROLE monitoring WITH SUPERUSER NOINHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'monitoring1234' VALID UNTIL 'infinity';

" | su - postgres -c "psql -Upostgres"


mv /var/lib/pgsql/${VERSION}/data/pg_hba.conf /var/lib/pgsql/${VERSION}/data/pg_hba.conf.$(date +%s)
echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     trust

# IPv4 local connections:
host    all             all             127.0.0.1/32            md5

# IPv6 local connections:
host    all             all             ::1/128                 md5

# Allow replication connections from localhost, by a user with the
# replication privilege.
host 	all				monitoring		0.0.0.0/0				md5
host 	replication		replication		0.0.0.0/0				md5
host  	all				all				0.0.0.0/0				md5" > /var/lib/pgsql/${VERSION}/data/pg_hba.conf

cmd "systemctl restart postgresql-${VERSION}"
lRC=$(($lRC + $?))



cmd "cat /var/lib/pgsql/${VERSION}/data/postgresql.auto.conf"
cmd "cat /var/lib/pgsql/${VERSION}/data/pg_hba.conf"

footer "END SCRIPT: $NAME"
exit $lRC