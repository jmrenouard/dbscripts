#!/bin/bash

source ./utils.sh
#--------------------
# CLEANUP
#--------------------

# ON VIRE LES BASES DE DONNES FINALES DEPUIS l'EXPORT DU SCHEMA
#title1 "DROP DATABASES FINALES"
#time bash ./drop_databases.sh $schema_file

# ON VIRE LES BASES DE DONNES DEDIEES POUR LES DUMP 
# LES BASES DE DONN2ES DUMP SONT PREFIXES PAR Dump20*
# ON VIRE TOUTES LES BASES NON SYSTEME
#db_user_list | grep -E '^Dump20'
for dbname in $(db_user_list); do
	title1 "DROP DATABASE \"$dbname\""
	echo "DROP DATABASE IF EXISTS \"$dbname\";" | sed -e 's/\"/`/g'| $raw_mysql -v
done

# LISTER LES BASES RESTANTES (IL N Y A QUE LA BASES SYSTEME)
db_list
pauseenter
