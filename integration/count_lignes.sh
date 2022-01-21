#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
count_dir=${1:-"counts"}

# Fichier de comptage des données
# Faire attention à la table reference
rm -rf $count_dir
mkdir -p $count_dir
for dbname in $(db_list | grep -Ev '(sys|_schema|mysql)'); do
	info "COMPTAGE DES LIGNES DES TABLES DE $dbname"
	db_count $dbname | tee -a $count_dir/count_${dbname}.txt
done
