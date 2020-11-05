#!/bin/sh

password=PhiShanohHohXohTh6
db=employees

rm -f /tmp/schema_*.sql

for srv in $1 $2; do 
	mysqldump -uroot -p$password --no-data -h $srv $db > /tmp/schema_$db_$srv.sql
done

diff /tmp/schema_*.sql