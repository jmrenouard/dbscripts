#!/bin/bash

source ./utils.sh
source ./env_info.sh

export NOPAUSE=1
export NOTRUNCATE=0
# Cleanup des tables
[ "$NOTRUNCATE" = "0" ] && for dumpdb in $(db_user_list| grep -E 'ARCHIVE'); do
	echo "TRUNCATE DUMP DB: $dumpdb"
	for dumptbl in $(db_tables "$dumpdb" | grep -vE '(general|slow)_log'); do
		if [ -f "failback" ]; then
			echo "SKIPPING TRUNCATE $dumpdb.$dumptbl due to FAILBACK( $(cat failback) )"
			continue
		fi
		echo "TRUNCATE TABLE $dumptbl;" | $raw_mysql "$dumpdb"
	done
done

# Pour toutes les databases Dump20xx
for dumpdb in $(db_user_list| grep -E '^Dump-20'); do
	echo "DATA DUMP DB: $dumpdb"
	dprefix=$(echo $dumpdb | cut -d_ -f2-)
	echo "DBTARGET: $dprefix"
	for dumptbl in $(db_tables "$dumpdb" | grep -vE '(general|slow)_log'); do
		if [ -f "failback" ]; then
			if [ "$dumpdb.$dumptbl" != "$(cat failback)" ] ;then
				echo "SKIPPING $dumpdb.$dumptbl due to FAILBACK( $(cat failback) )"
				continue
			else
				rm -f failback
			fi
		fi
		#echo -e "\t---------"
		#echo -e "\t *(ALL) $dumptbl\t$(echo "SELECT COUNT(*) FROM $dumptbl" | $raw_mysql "$dumpdb")"
		#echo -e "\t---------"
		for year in $(seq 2017 2024);do
			nbDateColumn=$(mysql -Nrs -e "SELECT count(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE (COLUMN_NAME = 'Date' OR COLUMN_NAME = 'Date_Heure' ) AND TABLE_SCHEMA = 'ARCHIVE_${year}_${dprefix}' AND TABLE_NAME = '$dumptbl'")
			if [ $nbDateColumn -eq 0 ]; then

				if [ "$dumptbl" = "Datas_Scan" ] || [ "$dumptbl" = "Machines" ] || [ "$dumptbl" = "mlx90365" ] || [ "$dumptbl" = "user" ]; then
					echo "SKIPPING $dumptbl (NO DATE TIME)"
					continue
				fi
				echo -n "$dumpdb.$dumptbl" > failback
				echo "ERROR: ARCHIVE_${year}_$dprefix.${dumptbl} <= $dumpdb.$dumptbl THERE IS NO DATETIME COLUMN"
				exit 4
			fi
			#dest_columns=$(mysql -Nrs ARCHIVE_${year}_$dprefix -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'ARCHIVE_${year}_${dprefix}' AND TABLE_NAME = '$dumptbl'")
			src_columns=$(mysql -Nrs ARCHIVE_${year}_$dprefix -e "SELECT group_concat(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$dumpdb' AND TABLE_NAME = '$dumptbl'")

			nbDateHeureColumn=$(mysql -Nrs -e "SELECT count(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'Date_Heure' AND TABLE_SCHEMA = 'ARCHIVE_${year}_${dprefix}' AND TABLE_NAME = '$dumptbl'")
			if [ $nbDateHeureColumn -gt 0 ]; then
				#echo -e "\t *($year) $dumptbl\t$(echo "SELECT COUNT(*) FROM $dumdb.$dumptbl WHERE YEAR(DATE_HEURE)=$year" | $raw_mysql $dumpdb)"
				mysql --show-warnings -v ARCHIVE_${year}_$dprefix -e "INSERT IGNORE INTO \`ARCHIVE_${year}_${dprefix}\`.${dumptbl} ($src_columns) SELECT * FROM \`$dumpdb\`.$dumptbl WHERE YEAR(DATE_HEURE)=$year"
				if [ "$?" != "0" ]; then
					echo -n "$dumpdb.$dumptbl" > failback
					echo "ERROR: ARCHIVE_${year}_$dprefix.${dumptbl} <= $dumpdb.$dumptbl"
					exit 5
				fi
			fi
			nbDateColumn=$(mysql -Nrs -e "SELECT count(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'Date' AND TABLE_SCHEMA = 'ARCHIVE_${year}_${dprefix}' AND TABLE_NAME = '$dumptbl'")
			if [ $nbDateColumn -gt 0 ]; then
				#echo -e "\t *($year) $dumptbl\t$(echo "SELECT COUNT(*) FROM $dumdb.$dumptbl WHERE YEAR(DATE)=$year" | $raw_mysql $dumpdb)"
				mysql -v ARCHIVE_${year}_$dprefix -e "INSERT IGNORE INTO \`ARCHIVE_${year}_${dprefix}\`.${dumptbl} ($src_columns) SELECT * FROM \`$dumpdb\`.$dumptbl WHERE YEAR(DATE)=$year"
				if [ "$?" != "0" ]; then
					echo -n "$dumpdb.$dumptbl" > failback
					echo "ERROR: ARCHIVE_${year}_$dprefix.${dumptbl} <= $dumpdb.$dumptbl"
					exit 5
				fi
			fi
		done
	done
done
rm -f failback

exit 0
