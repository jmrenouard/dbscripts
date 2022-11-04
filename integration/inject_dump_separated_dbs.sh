#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
DUMP_DIR=${1:-"$DEFAULT_DUMP_DIR"}
DB_PREFIX=${2:-"$(echo $DUMP_DIR| cut -d_ -f1 |perl -pe 's/(\d{4})(\d{2})(\d{2})/-$1-$2/g')_"}
DOIT=${DOIT:-"1"}
echo "$DB_PREFIX"
#exit 0
DB_LIST="$(get_database_names $DUMP_DIR)"
info "$DB_LIST"
for dbname in $DB_LIST; do
	echo "DROP DATABASE IF EXISTS \"${DB_PREFIX}$dbname\";"
	echo "CREATE DATABASE \"${DB_PREFIX}$dbname\";"
done | sed -e 's/\"/`/g' | $mysql_force -v

DB_LIST_DUMP="$(db_user_list | grep -E "^$DB_PREFIX")"
info "DUMP: $DB_LIST_DUMP"
for dbname in $DB_LIST; do
	title2 "GESTION DES FICHIERS SQL POUR $dbname du DUMP $DUMP_DIR"
	for sqlfile in $(ls -1 $DUMP_DIR |grep -E "^${dbname}_"); do
		echo "---------------------------------------------------"
		echo "INJECTING de $sqlfile dans ${DB_PREFIX}$dbname"
		echo "---------------------------------------------------"
		date
		info "Injection de $sqlfile dans ${DB_PREFIX}$dbname"
		info "cat $DUMP_DIR/$sqlfile |sed "s/$dbname/${DB_PREFIX}$dbname/g" | $raw_mysql -f " 
		sed "s/$dbname/${DB_PREFIX}$dbname/g" $DUMP_DIR/$sqlfile | $raw_mysql ${DB_PREFIX}$dbname
	done
done
