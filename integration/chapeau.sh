#!/bin/bash

rm -f "${0}.log"

(
source ./utils.sh
source ./env_info.sh

DROP_DB=0
INJECT_DB=0
INJECT_SCHEMA=1

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
[ "$INJECT_SCHEMA" = "1" ] && time bash ./inject_all_schemas.sh $DEFAULT_SCHEMA_SQL_FILE
exit 0


#--------------------
# CREATION DES SCHEMAS FINALES DEPUIS LE SCHEMA DU DERNIER DUMP
#--------------------
# NOUS AVONS CONSTATE Qu'il N'y a pas les routines et les vues
# NOUS REINJECTONS LES SCHEMAS DEPUIS L EXPORT COMPLET DES SCHEMAS DES BASES DE DONNN2ES DU DERNIER DUMP CONNUES (Dump20211123_***)
title1 "INJECTION SCHEMAS DATABASES FINALES DEPUIS LE SCHEMAS DU DERNIER DUMP"
[ "$INJECT_SCHEMA" = "1" ] && time bash ./inject_new_database_from_last_dump.sh
pauseenter

#exit 0
#--------------------
# CONSOLIDATION DES DONN2ES DANS LES BASES FINALES
#--------------------
# RECOPIE DES DONNEES DES BASES DE DUMP VERS LES BASES DE DONNEES FINALES
title1 "INJECT DATA FROM DUMP DATABASES"
time bash ./inject_data_from_dump_databases.sh

#--------------------
# INJECTION DES DONNEES DE LA BASE PRODUCTION
#--------------------
# INJECTION DES DONNEES SPECIFIQUES A LA BASE PRODUCTION
title1 "INJECTION DONNEES BASE PRODUCTION"
db_count production
$raw_mysql < ./production_data.sql
db_count production
pauseenter

#--------------------
# TESTS
#--------------------
# Comptage du nombre de ligne pour chaque table de chaque base (un fichier de comptage par database)
title1 "COUNT LINE INTO TABLE DATABASES"
time bash ./count_lignes.sh counts

title1 "AGGREGATION DES RESULTATS TABLE a TABLE PAR BASE DE DONNEE FINALE"
time bash ./aggregate_comptage.sh counts

) 2>&1 | tee -a ${0}.log