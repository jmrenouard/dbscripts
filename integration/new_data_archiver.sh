#!/bin/bash

rm -f "${0}.log"

(
source ./utils.sh
source ./env_info.sh

DB_LIST=$(get_db_list_from_dir Dump202*)


for db in $DB_LIST; do
    echo "-- $db WITH DATE_HEURE"
    for tbl in $(mysql -Nrs -e "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db' AND COLUMN_NAME='DATE_HEURE'"); do
        echo "-- $db.$tbl"
        #src_columns=$(mysql -Nrs ${db}_ARCHIVE_${y} -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db' AND TABLE_NAME ='$tbl'")
        for y in $(seq 2017 2022); do
            echo "TRUNCATE TABLE \`${db}_ARCHIVE_${y}\`.${tbl};"
            echo "INSERT IGNORE INTO \`${db}_ARCHIVE_${y}\`.${tbl} SELECT * FROM \`$db\`.$tbl WHERE YEAR(DATE_HEURE)=$y;"
        done
    done
    echo "-- $db WITH DATE"
    for tbl in $(mysql -Nrs -e "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db' AND COLUMN_NAME='DATE'"); do
        echo "-- $db.$tbl"
        #src_columns=$(mysql -Nrs ${db}_ARCHIVE_${y} -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db' AND TABLE_NAME ='$tbl'")
        for y in $(seq 2017 2022); do
            echo "TRUNCATE TABLE \`${db}_ARCHIVE_${y}\`.${tbl};"
            echo "INSERT IGNORE INTO \`${db}_ARCHIVE_${y}\`.${tbl} SELECT * FROM \`$db\`.$tbl WHERE YEAR(DATE)=$y;"
        done
    done
done > ARCHIVE_DATA.sql

cat ARCHIVE_DATA.sql | mysql -v

echo "Fin..."
) 2>&1 | tee -a ${0}.log

	#	echo "TRUNCATE TABLE $dumptbl;" | $raw_mysql -v "$dumpdb"
