#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
SQL_FILE=${1:-"$DEFAULT_SCHEMA_SQL_FILE"}



banner "CREATING DBS"

title2 "AVANT INJECTION DES BASES"
db_list
grep "CREATE " $SQL_FILE | grep DATABASE  | mysql -f -v
title2 "APRES INJECTION DES BASES"
db_list
