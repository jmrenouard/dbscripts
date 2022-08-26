#!/bin/bash

source ./utils.sh 
source ./env_info.sh

SQL_FILE=${1:-"$DEFAULT_SCHEMA_SQL_FILE"}

banner "DROPPING DB"

title2 "AVANT PURGE DES BASES"
db_list
grep "CREATE " $SQL_FILE | grep DATABASE | perl -pe 's/\/\*.*?\*\///g;s/CREATE/DROP/g;s/IF NOT EXIST/IF/g' | mysql -f -v
title2 "APRES PURGE DES BASES"
db_list
