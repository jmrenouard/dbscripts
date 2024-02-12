#!/bin/bash

source ./utils.sh
lRC=0
BCK_DIR="./exports"
GZIP_CMD=pigz

rm -Rf $BCK_DIR
mkdir -p $BCK_DIR
for dbname in $(db_user_list); do
	BCK_FILE="${BCK_DIR}/${dbname}.sql.gz"
	title1 "EXPORT $dbname"
	info "Backup logique mysldump dans le fichier $BCK_FILE"
title1 "Command: time mysqldump \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction $dbname | $GZIP_CMD > $BCK_FILE"

time mysqldump \
--add-drop-database \
--routines \
--skip-opt \
--triggers \
--add-drop-table --add-locks --create-options --disable-keys --extended-insert \
--quick --set-charset \
--single-transaction $dbname | $GZIP_CMD > $BCK_FILE
	lRC=$(($lRC +$?))
	info "RETURN CODE $lRC"
	#break
done

info "RETURN CODE $lRC"
exit $lRC
