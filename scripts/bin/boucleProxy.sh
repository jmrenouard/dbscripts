#!/bin/sh

for i in $(seq 1 500); do 
mysql -hproxy1 -uroot -ppheekeesee0AhQu4ai employees -e 'show variables like "report_host%"' -Nrs; sleep 1s;done

