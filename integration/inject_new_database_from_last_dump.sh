#!/bin/bash

source ./utils.sh 
export NOPAUSE=1

#Dernier dump directory
dump_dir=$(ls -1 $DUMP_DIR |grep -E "^Dump20"| sort -n | tail -n 1)
prefix="$(echo $dump_dir| cut -d_ -f1 |perl -pe 's/(\d{4})(\d{2})(\d{2})/-$1-$2/g')_"

for dbname in $(db_list | grep -E "^$prefix");do
	target_dbname=$(echo $dbname| cut -d_ -f2-)
	for prefix in ARCHIVE_2017_ ARCHIVE_2018_ ARCHIVE_2019_ ARCHIVE_2020_ ARCHIVE_2021_ ARCHIVE_2022_ ARCHIVE_2023_ ARCHIVE_2024_; do
		info "DUMPING SCHEMA FROM ${dbname} TO $prefix$target_dbname"
		mysqldump --no-data --add-drop-database --add-drop-table --routines --events --triggers --databases ${dbname} | sed -E "s/${dbname}/$prefix$target_dbname/g" | $raw_mysql
	done
done

echo "ARCHIVE DATABASE FROM $dump_dir"