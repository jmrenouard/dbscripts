#!/bin/bash

source ./utils.sh
#--------------------
# CREATION DES SCHEMAS FINALES
#--------------------
# CREATION DES BASES FINALES A PARTIR DU SCHEMA
#title1 "CREATE DATABASES FINALES"
#bash ./create_databases.sh $schema_file
#pauseenter

# INJECTION DES STRUCTURES DE BASE DE DONNEES A PARTIR DU SCHEMA
#title1 "INJECTION SCHEMAS DATABASES FINALES"
#bash ./inject_all_schemas.sh $schema_file
#pauseenter

# NOUS AVONS CONSTATE Qu'il N'y a pas les routines et les vues
# NOUS REINJECTONS LES SCHEMAS DEPUIS L EXPORT COMPLET DES SCHEMAS DES BASES DE DONNN2ES DU DERNIER DUMP CONNUES (Dump20211123_***)
title1 "INJECTION SCHEMAS DATABASES FINALES DEPUIS LE DERNIERS DUMPS"
time bash ./inject_new_database_from_last_dump.sh
pauseenter
