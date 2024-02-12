#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

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
" | tee /etc/my.cnf.d/91_audit_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING SERVER AUDIT PLUGIN"
mysql  -v -e "INSTALL SONAME 'server_audit';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC