#!/bin/bash
RES_DIR="${1:-"sys_result"}"
DB="${2:-"sys"}"

MYSQL="mysql -B"
MYSQL_RAW="mysql -Nrs"

db_tables() {
	$MYSQL_RAW -e 'SHOW TABLES;' "${1:-"sys"}"
}

[ -d "$RES_DIR" ] || mkdir -p "$RES_DIR"

for t in $(db_tables "$DB"); do
	echo "* Exporting $DB.$t"
	time $MYSQL  -e "select * from $t;" "$DB"| sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > "${RES_DIR}/${t}.csv"
    head -n 3 "${RES_DIR}/${t}.csv"
    perl -pe 's/\"\,\"/"\t"/g' "${RES_DIR}/${t}.csv" > "${RES_DIR}/${t}.tsv"
done
tar czvf "$(basename "$RES_DIR").tar.gz" "$RES_DIR"

echo "* Result into: $(basename "$RES_DIR")"
