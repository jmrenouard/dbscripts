#!/bin/bash

source ./utils.sh 

export NOPAUSE=1
export DOIT=1

#!/bin/bash

source ./utils.sh 
source ./env_info.sh

#--------------------
# CREATION DES SCHEMAS FINALES
#--------------------
#time bash ./create_final_schemas.sh
pauseenter

#--------------------
# CONSOLIDATION DES DONN2ES DANS LES BASES FINALES
#--------------------
# RECOPIE DES DONNEES DES BASES DE DUMP VERS LES BASES DE DONNEES FINALES
title1 "INJECT DATA FROM DUMP DATABASES"
#time bash ./inject_data_from_dump_databases.sh

#--------------------
# TESTS
#--------------------
# Comptage du nombre de ligne pour chaque table de chaque base (un fichier de comptage par database)
title1 "COUNT LINE INTO TABLE DATABASES"
time bash ./count_lignes.sh counts

title1 "AGGREGATION DES RESULTATS TABLE a TABLE PAR BASE DE DONNEE FINALE"
time bash ./aggregate_comptage.sh counts

