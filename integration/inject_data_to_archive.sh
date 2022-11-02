#!/bin/bash

source ./utils.sh

export NOPAUSE=1
export NOTRUNCATE=1
# Cleanup des tables
[ "$NOTRUNCATE" = "0" ] && for dumpdb in $(db_user_list| grep -E '^ARCHIVE' | grep -v production); do
	echo "DUMP DB: $dumpdb"
	for dumptbl in $(db_tables "$dumpdb" | grep -vE '(general|slow)_log'); do
		echo "TRUNCATE TABLE $dumptbl;" | $raw_mysql -v "$dumpdb"
	done
done

# Pour toutes les databases Dump20xx
for dumpdb in $(db_user_list| grep -E '^Dump20'| grep -vE '(production|user)'); do
	echo "DUMP DB: $dumpdb"
	dprefix=$(echo $dumpdb | cut -d_ -f2-)
	echo "DBTARGET: $dprefix"
	for dumptbl in $(db_tables "$dumpdb" | grep -vE '(general|slow)_log'); do
		if [ -f "failback" ]; then
			if [ "$dumpdb.$dumptbl" != "$(cat failback)" ] ;then
				echo "SKIPPING _$dumpdb.$dumptbl due to FAILBACK( $(cat failback) )"
				continue
			else 
				rm -f failback
			fi
		fi
		echo -e "\t---------"
		echo -e "\t *(ALL) $dumptbl\t$(echo "SELECT COUNT(*) FROM $dumptbl" | $raw_mysql "$dumpdb")"
		echo -e "\t---------"
		for year in $(seq 2017 2024);do
			echo -e "\t *($year) $dumptbl\t$(echo "SELECT COUNT(*) FROM $dumdb.$dumptbl WHERE YEAR(DATE_HEURE)=$year" | $raw_mysql $dumpdb)"
			#echo "INSERT IGNORE INTO ARCHIVE_${year}_${dprefix}.${dumptbl} SELECT * FROM $dumpdb.$dumptbl WHERE YEAR(DATE_HEURE)=$year"
			dest_columns=$(mysql -Nrs ARCHIVE_${year}_$dprefix -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'ARCHIVE_${year}_${dprefix}' AND TABLE_NAME = '$dumptbl'")
			src_columns=$(mysql -Nrs ARCHIVE_${year}_$dprefix -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$dumpdb' AND TABLE_NAME = '$dumptbl'")
			
			mysql --show-warnings -v ARCHIVE_${year}_$dprefix -e "INSERT IGNORE INTO \`ARCHIVE_${year}_${dprefix}\`.${dumptbl} ($src_columns) SELECT * FROM \`$dumpdb\`.$dumptbl WHERE YEAR(DATE_HEURE)=$year"
			if [ "$?" != "0" ]; then
			 echo -n "$dumpdb.$dumptbl" > failback
			 exit 4
			fi
		done
	done
done
exit 0
