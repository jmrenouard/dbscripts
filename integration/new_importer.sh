#!/bin/bash

rm -f "${0}.log"

(
source ./utils.sh
source ./env_info.sh

DROP_DB=1
#INJECT_DB=1
#INJECT_SCHEMA=1
export NOPAUSE=1
#--------------------
# CLEANUP
#--------------------
# ON VIRE LES BASES DE DONNES DEDIEES POUR LES DUMP
# LES BASES DE DONN2ES DUMP SONT PREFIXES PAR Dump20*
# ON VIRE TOUTES LES BASES NON SYSTEME
#db_user_list | grep -E '^Dump20'
[ "$DROP_DB" = "1" ] && for dbname in $(db_user_list); do
	echo "DROP DATABASE IF EXISTS \"$dbname\";"
done| sed -e 's/\"/`/g'| $raw_mysql -v


# Changing file name
for d in Dump20*; do
    (
        cd $d
        for sqlfile in *.sql;do
            echo "$sqlfile" | grep -q '_efi'
            if [ $? -eq 0 ]; then
                echo "mv $d/$sqlfile $d/$(echo $sqlfile| sed 's/_efi/-efi/g')"
            fi
        done
    )
done > rename_efi_sqlfile.sh

bash rename_efi_sqlfile.sh
find . -type f -iname '*efi*.sql'

DB_LIST=$(get_db_list_from_dir Dump202*)

for db in $DB_LIST; do
    echo "CREATE DATABASE IF NOT EXISTS \`$db\`;"
    for y in $(seq 2017 2022); do
        echo "CREATE DATABASE  IF NOT EXISTS \`${db}_ARCHIVE_${y}\`;"
    done
done > CREATE_DATABASES.sql


# Renommage des fichier efi
# Pour chaque réperoire Dump
ls -ls $LAST_DUMP_DIR

# Inject Last schemas
rm -f CREATE_TABLES_*.sql INSERTS_*.sql
for sqlfile in $LAST_DUMP_DIR/*.sql; do
    dbname=$(basename $sqlfile| cut -d_ -f1)
    [ "$dbname" = "production" ] && continue
    [ "$dbname" = "sys" ] && continue
    grep -vE '^(LOCK TABLE|INSERT.*\(|--)' $sqlfile >> CREATE_TABLES_${dbname}.sql
    grep -E '^(INSERT.*\(|--)' $sqlfile | sed -E '/INSERT.*\(\s*$/d' >> INSERTS_${dbname}.sql
    echo "* CREATE_TABLES_${dbname}.sql ... done"
done
perl -i -pe 's/(ENGINE=)ndbcluster/$1InnoDB/g' CREATE_TABLES_*.sql

mysql < CREATE_DATABASES.sql
mysql < production.sql

for db in $DB_LIST; do
    echo "* Injecting $db info structure"
    cat CREATE_TABLES_${db}.sql | mysql -f "$db"
#    [ $? -eq 0 ] || break
    for y in $(seq 2017 2022); do
        cat CREATE_TABLES_${db}.sql | mysql -f "${db}_ARCHIVE_${y}"
    done
done

for db in $DB_LIST; do
    echo "* Injecting $db DATA"
    cat INSERTS_${db}.sql | mysql -f "$db"
done

echo "Fin..."
) 2>&1 | tee -a ${0}.log
