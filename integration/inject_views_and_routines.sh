#!/bin/bash

source ./utils.sh

export NOPAUSE=1



#Dernier dump directory
dump_dir=$(ls -1 $DUMP_DIR |grep -E "^Dump20"| sort -n | tail -n 1)
prefix=$(echo $dump_dir| cut -d_ -f1)_


for dbname in $(db_list | grep -E "^$prefix");do
	target_dbname=$(echo $dbname| cut -d_ -f2-)
	info "DUMPING VIEWS FROM ${dbname} TO $target_dbname"
	for view in $($raw_mysql INFORMATION_SCHEMA -e "select table_name from tables where table_type = 'VIEW' and table_schema = '$dbname'"); do
		echo "-- DUMPING VIEW $view FOR $dbname"
		mysqldump $dbname $view | $raw_mysql $target_dbname
	done
	info "DUMPING ROUTINES FROM ${dbname} TO $target_dbname"
	mysqldump -n -d -t --routines --triggers ${dbname} | $raw_mysql $target_dbname
done
