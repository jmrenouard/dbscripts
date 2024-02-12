#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
SQL_FILE=${1:-"$DEFAULT_SCHEMA_SQL_FILE"}

title2 "AVANT INJECTION DES SCHEMAS"
#sed -e '/CREATE DATABASE/d' $SQL_FILE | 
perl -pe 's/(ENGINE=)ndbcluster/$1InnoDB/g' $SQL_FILE | $raw_mysql -f
if [ $? -eq 0 ];then
	ok "INJECTION SCHEMAS OK"
else 
	error "ERROUR DURANT INJECTION"
fi

