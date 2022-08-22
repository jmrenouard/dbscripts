#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
DUMP_DIR=${1:-"$DEFAULT_DUMP_DIR"}
DB_PREFIX=${2:-"$(echo $DUMP_DIR| cut -d_ -f1)_"}
DOIT=${DOIT:-"1"}

get_database_names()
{
	ls -1 $1 |grep -vE '^sys_' | cut -d_ -f 1 | sort | uniq
}

DB_LIST="$(get_database_names $DUMP_DIR | grep -vE '(production|-efi)')"
info "$DB_LIST"
for dbname in $TARGET_DB_LIST; do
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
		sed "s/$dbname/${DB_PREFIX}$dbname/g" $DUMP_DIR/$sqlfile | $raw_mysql -f ${DB_PREFIX}$dbname
	done
done
