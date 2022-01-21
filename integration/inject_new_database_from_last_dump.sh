#!/bin/bash

source ./utils.sh 
export NOPAUSE=1

#Dernier dump directory
dump_dir=$(ls -1 $DUMP_DIR |grep -E "^Dump20"| sort -n | tail -n 1)
prefix=$(echo $dump_dir| cut -d_ -f1)_

for dbname in $(db_list | grep -E "^$prefix");do
	target_dbname=$(echo $dbname| cut -d_ -f2-)
	info "DUMPING SCHEMA FROM ${dbname} TO $target_dbname"
	mysqldump --no-data --add-drop-database --add-drop-table --routines --events --triggers --databases ${dbname} | sed -E "s/${dbname}/$target_dbname/g" | $raw_mysql -f
done
