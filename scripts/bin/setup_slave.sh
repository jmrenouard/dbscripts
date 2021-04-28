#!/bin/sh

master=$1
user=replication
pass=$2

datadir=/var/lib/mysql

systemctl stop mariadb

rm -rf $datadir/*

cd $datadir
ssh -q $master "mariabackup --user=root --backup --stream=mbstream" | mbstream -v -x

# ...
# CHANGE MASTER

systemctl start mariadb

mysql -e 'start slave;'
