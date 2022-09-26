#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh

banner "BEGIN SCRIPT: $_NAME"

#cmd "create_database.sh employees employees employees_rw employees_ro"
cmd "create_database.sh employees employees employees_rw employees_ro"


cd /opt/local
cmd "git clone https://github.com/datacharmer/test_db.git"

cd /opt/local/test_db

title2 "Inject DATABASE employees"
#mysql  < ./employees.sql
perl -ne '/DROP DATABASE/ or /CREATE DATABASE/ or /USE employees/ or print' ./employees.sql | mysql employees
cmd "db_tables employees"

cmd "db_count employees"

cmd "list_user.sh"

footer "END SCRIPT: $NAME"

exit $lRC
