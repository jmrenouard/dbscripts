#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

lRC=0
banner "SERVER AUDIT PLUGIN ACTIVATION"

#CONNECT	Connects, disconnects and failed connects—including the error code
#QUERY	Queries executed and their results in plain text, including failed queries due to syntax or permission errors
#TABLE	Tables affected by query execution
#QUERY_DDL	Similar to QUERY, but filters only DDL-type queries (CREATE, ALTER, DROP, RENAME and TRUNCATE statements—except CREATE/DROP [PROCEDURE / FUNCTION / USER] and RENAME USER (they're not DDL)	MariaDB 5.5.42. MariaDB 10.0.17, MariaDB 10.1.4
#QUERY_DML	Similar to QUERY, but filters only DML-type queries (DO, CALL, LOAD DATA/XML, DELETE, INSERT, SELECT, UPDATE, HANDLER and REPLACE statements)	MariaDB 5.5.42, MariaDB 10.0.17, MariaDB 10.1.4
#QUERY_DML_NO_SELECT	Similar to QUERY_DML, but doesn't log SELECT queries. (since version 1.4.4) (DO, CALL, LOAD DATA/XML, DELETE, INSERT, UPDATE, HANDLER and REPLACE statements)	MariaDB 5.5.42, MariaDB 10.0.17, MariaDB 10.1.4
#QUERY_DCL 		Similar to QUERY, but filters only DCL-type queries (CREATE USER, DROP USER, RENAME USER, GRANT, REVOKE and SET PASSWORD statements)

title2 "CREATE CONFIG FILE FOR SERVER AUDIT"
echo "[mariadb]
plugin_load_add = server_audit
server_audit=FORCE_PLUS_PERMANENT
server_audit_logging=ON
server_audit_output_type=file
server_audit_file_rotate_now=ON
server_audit_file_rotate_size=1000000
server_audit_file_rotations=5
server_audit_events=CONNECT,QUERY_DDL,QUERY_DCL
server_audit_file_path=audit.log;
" | tee /etc/my.cnf.d/91_audit_plugin.cnf

title1 "APPLYING AUDIT CONFIGURATION VIA SQL"
cmd "echo \"
SET GLOBAL server_audit_logging=ON;
SET GLOBAL server_audit_output_type=file;
SET GLOBAL server_audit_file_path='audit.log';
SET GLOBAL server_audit_file_rotate_now=ON;
SET GLOBAL server_audit_file_rotate_size=1000000;
SET GLOBAL server_audit_file_rotations=5;
SET GLOBAL server_audit_events='CONNECT,QUERY_DDL,QUERY_DCL';
\" | mysql -v -f" "SETTING AUDIT SYSTEM VARIABLES"
lRC=$?

# Version enterprise
# https://mariadb.com/docs/server/security/audit/enterprise-audit/
#<timestamp>,<serverhost>,<username>,<host>,<connectionid>,<queryid>,<operation>,<database>,<object>,<retcode>
#echo "INSERT INTO mysql.server_audit_filters (filtername, rule)   
#VALUES ('reporting',      
#JSON_COMPACT( '{ \"connect_event\": [ \"CONNECT\", \"DISCONNECT\" ],
#\"table_event\":[ 
#\"WRITE\", \"CREATE\", \"DROP\", \"RENAME\", \"ALTER\" ] }'));" | mysql -v -f
#SET GLOBAL server_audit_reload_filters=ON;

#title2 "RESTARTING MARIADB SERVER"
#cmd "systemctl restart mariadb"
#lRC=$(($lRC + $?))

cmd "mysql -v -e \"INSTALL SONAME 'server_audit';\"" "INSTALLING SERVER AUDIT PLUGIN"
lRC=$?

footer "END SCRIPT: $NAME"
exit $lRC