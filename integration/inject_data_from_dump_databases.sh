#!/bin/bash

source ./utils.sh 

export NOPAUSE=1

for dump_dir in $(ls -1 | grep 'Dump20'| sort -n); do
	prefix=$(echo $dump_dir| cut -d_ -f1)_
	for dump_dbname in $(db_list | grep -E "^$prefix"); do
		target_dbname="$(echo $dump_dbname| cut -d_ -f2)"
		title2 "INJECTING DATA FROM $dump_dbname TO $target_dbname"
		info "mysqldump --skip-triggers --complete-insert -n -t $dump_dbname | $raw_mysql $target_dbname"
		mysqldump --skip-triggers --complete-insert -n -t $dump_dbname | $raw_mysql -f $target_dbname 
		if [ $? -ne 0 ]; then
			error "FAILURE INSERTING DATA"
		else
			ok "DATA INJECTED FROM $dump_dbname TO $target_dbname"
		fi
	done
done

