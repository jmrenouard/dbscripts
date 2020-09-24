#!/bin/sh

db_list()
{
   mysql -Nrs -e 'show databases'
}

db_tables()
{
    mysql -Nrs -e 'show tables' ${1:-"mysql"}
}

db_count()
{
    for tbl in $(db_tables ${1:-"mysql"}); do
        echo -ne "$tbl\t"
        mysql -Nrs -e "select count(*) from $tbl" ${1:-"mysql"}
    done | sort -nr -k2 | column -t
}

db_tables employees

db_count employees