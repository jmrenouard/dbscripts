#!/bin/sh

for srv in mariadb1 mariadb2 mariadb3 mariadb4 haproxy1; do
	timeout 30s sudo vagrant up $srv
done
