#!/bin/sh

BCK_FILE=/data/backups/mariabackup/$(date +%Y%m%d-%H%M).xbstream.gz

# GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, PROCESS ON *.* to 'mariabackup'@'localhost' identified by 'mariabackup';

time mariabackup --backup --user=mariabackup --password=mariabackup --stream=xbstream | gzip > $BCK_FILE


echo " Pour recuperer les fichiers: "
echo "mkdir tmp"
echo "cd tmp"
echo "gunzip -c $BCK_FILE | mbstream -x"
