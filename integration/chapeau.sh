#!/bin/bash

rm -f "${0}.log"

(
source ./utils.sh
source ./env_info.sh

DROP_DB=1
INJECT_DB=0
INJECT_SCHEMA=0
INJECT_ARCHIVE_DATA=0
COUNT_DATA=0
AGGREGATE_RESULT=0
BACKUP_DBS=0
GEN_RESTORE_SCRIPT=1
REINJECT_DBS=1
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

# LISTER LES BASES RESTANTES (IL N Y A QUE LA BASES SYSTEME)
db_list
pauseenter
#--------------------
# INJECTION DES EXPORTS DANS LES BASES DE DUMP
#--------------------
# INJECTION DES DONNEES DES EXPORTS DUMP DANS LES BASES SPECIFIQUES A CHAQUE REPERTOIRE DE DUMP 
[ "$INJECT_DB" = "1" ] && for dump_dir in $(ls -1 | grep -E '^Dump20' ); do
	title1 "INJECTION DATABSE & DATA INTO SEPARATED DB FOR $dump_dir"
	info "time bash inject_dump_separated_dbs.sh $dump_dir"
	time bash inject_dump_separated_dbs.sh "$dump_dir"
	pauseenter
done
#INJECT SCHEMAS (CONTAINING PRODUCTION AND EFI DATABASES SCHEMAS)
#[ "$INJECT_SCHEMA" = "1" ] && time bash ./inject_all_schemas.sh $DEFAULT_SCHEMA_SQL_FILE
#exit 0


#--------------------
# CREATION DES SCHEMAS FINALES DEPUIS LE SCHEMA DU DERNIER DUMP
#--------------------
# NOUS AVONS CONSTATE Qu'il N'y a pas les routines et les vues
# NOUS REINJECTONS LES SCHEMAS DEPUIS L EXPORT COMPLET DES SCHEMAS DES BASES DE DONNN2ES DU DERNIER DUMP CONNUES (Dump20211123_***)
if [ "$INJECT_SCHEMA" = "1" ];then
	title1 "INJECTION SCHEMAS DATABASES FINALES DEPUIS LE SCHEMAS DU DERNIER DUMP"
	time bash ./inject_new_database_from_last_dump.sh
	pauseenter

	for year in $(seq 2017 2024); do
		mysqldump --no-data --add-drop-table Dump-2022-08_hyu1309-act-theta3 st30_assemblage_soupape | mysql ARCHIVE_${year}_hyu1309-act-theta3
	done
fi
if [ "$INJECT_ARCHIVE_DATA" = "1" ]; then
#--------------------
# CONSOLIDATION DES DONN2ES DANS LES BASES FINALES
#--------------------
# RECOPIE DES DONNEES DES BASES DE DUMP VERS LES BASES DE DONNEES FINALES
title1 "INJECT DATA FROM DUMP DATABASES"
#time bash ./inject_data_from_dump_databases.sh
time bash ./inject_data_to_archive.sh
fi

#--------------------
# INJECTION DES DONNEES DE LA BASE PRODUCTION
#--------------------
# INJECTION DES DONNEES SPECIFIQUES A LA BASE PRODUCTION
#title1 "INJECTION DONNEES BASE PRODUCTION"
#db_count production
#$raw_mysql < ./production_data.sql
#db_count production
#pauseenter

if [ "$COUNT_DATA" = "1" ]; then

#--------------------
# TESTS
#--------------------
# Comptage du nombre de ligne pour chaque table de chaque base (un fichier de comptage par database)
title1 "COUNT LINE INTO TABLE DATABASES"
time bash ./count_lignes.sh counts
fi

if [ "$AGGREGATE_RESULT" = "1" ]; then
title1 "AGGREGATION DES RESULTATS TABLE a TABLE PAR BASE DE DONNEE FINALE"
time bash ./aggregate_comptage.sh counts
fi

if [ "$BACKUP_DBS" = "1" ]; then
title1 "Backup all DBs"

rm -rf $BACKUP_DIR
mkdir -p $BACKUP_DIR
	for db in $(db_user_list); do
		echo "* Backup $db DATABASE"
		mysqldump \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction $db | pigz > $BACKUP_DIR/$db.sql.gz
	done
fi

if [ "$GEN_RESTORE_SCRIPT" = "1" ]; then
	title1 "GENERATE RESTORE SCRIPT"
	(
		echo "#!/bin/bash -x"
		for db in $(ls -1  $BACKUP_DIR | grep sql.gz | cut -d. -f1); do
			echo "echo '## $db DATABSE INJECTION'"
			echo "echo '#########################################'"
			echo "echo 'DROP DATABASE IF EXISTS \`$db\`; CREATE DATABASE IF NOT EXISTS \`$db\`;' | mysql -v"
			echo "cat ./$db.sql.gz | pigz -cd | mysql $db"
			echo "echo '$db INJECTED ....'"
			echo "echo '#########################################'"
		done
	) | tee  $BACKUP_DIR/inject_all.sh
	(
		echo "#!/bin/bash -x"
		for db in $(ls -1  $BACKUP_DIR |grep -i archive | grep sql.gz | cut -d. -f1); do
			echo "echo '## $db DATABSE INJECTION'"
			echo "echo '#########################################'"
			echo "echo 'DROP DATABASE IF EXISTS \`$db\`; CREATE DATABASE IF NOT EXISTS \`$db\`;' | mysql -v"
			echo "cat ./$db.sql.gz | pigz -cd | mysql $db"
			echo "echo '$db INJECTED ....'"
			echo "echo '#########################################'"
		done
	) | tee  $BACKUP_DIR/inject_archives.sh
	(
		echo "#!/bin/bash -x"
		for db in $(ls -1  $BACKUP_DIR |grep -i dump | grep sql.gz | cut -d. -f1); do
			echo "echo '## $db DATABSE INJECTION'"
			echo "echo '#########################################'"
			echo "echo 'DROP DATABASE IF EXISTS \`$db\`; CREATE DATABASE IF NOT EXISTS \`$db\`;' | mysql -v"
			echo "cat ./$db.sql.gz | pigz -cd | mysql $db"
			echo "echo '$db INJECTED ....'"
			echo "echo '#########################################'"
		done
	) | tee  $BACKUP_DIR/inject_dumps.sh
fi

if [ "$REINJECT_DBS" = "1" ];then
	( cd $BACKUP_DIR
	bash inject_archives.sh
	)
fi
) 2>&1 | tee -a ${0}.log