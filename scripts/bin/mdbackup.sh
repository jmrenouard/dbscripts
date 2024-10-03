#!/usr/bin/env bash

load_lib()
{
    libname="$1"
    if [ -z "$libname" -o "$libname" = "main" ];then 
        libname="utils.sh"
    else 
        libname="utils.$1.sh"
    fi
    _DIR="$(dirname "$(readlink -f "$0")")"
    if [ -f "$_DIR/$libname" ]; then
        source $_DIR/$libname
    else
        if [ -f "/etc/profile.d/$libname" ]; then
            source /etc/profile.d/$libname
        else 
            echo "No $libname found"
            exit 127
        fi
    fi
}
load_lib main
load_lib mysql

DBNAME="$1"
[ -z "$DBNAME" ] && die "NO DATABASE NAME AS PARAMETER"

TABLE="${2:-"ALL"}"
FORMAT="${3:-"SQL"}"

TABLE_TARGET=""
for tbl in $(echo $TABLE| tr ',' ' '); do
    TABLE_TARGET="${TABLE_TARGET}${DBNAME}.${tbl},"
done
TABLE_TARGET=$(echo $TABLE_TARGET| sed -E 's/,$//')
BCK_DIR=/data/backups/mydumper/$DBNAME-$(echo $TABLE|tr ',' '-')
#TABLE=$TABLE_TARGET
GZIP_CMD=pigz
#GZIP_CMD=gzip
#GZIP_CMD=tee
GALERA_SUPPORT=$(galera_is_enabled)
KEEP_LAST_N_BACKUPS=5
BCK_TARGET=$BCK_DIR/$(date +%Y%m%d-%H%M%S)

[ -f "/etc/mdconfig.sh" ] && source /etc/mdconfig.sh

lRC=0

banner "LOGICAL BACKUP WITH MYDUMPER"
my_status
if [ $? -ne 0 ]; then
    error "LOGICAL BACKUP FAILED: Server must be running ...."
    lRC=2 footer "LOGICAL BACKUP"
	exit 2
fi

db_list | grep -qE "^${DBNAME}$"
[  $? -ne 0 ] && die "NO DATABASE CALLED $DBNAME EXISTS"

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "Desynchronisation du noeud"
    # desync
    mysql -e 'set global wsrep_desync=on'

    info  "etat Desynchronisation"
    mysql -e 'select @@wsrep_desync'
fi
[ -d "$BCK_TARGET" ] || mkdir -p $BCK_TARGET

table_target="-T $TABLE"
if [ "$TABLE" == "ALL" -o "$TABLE" == "all" ]; then
    table_target=""
fi
output_format=""
if [ "$FORMAT" == "CSV" -o "$FORMAT" == "csv" ]; then
    output_format="--csv"
fi
info "Backup logique mydumper dans le repertoire $BCK_TARGET"
title1 "Command: time mydumper \
  --database=$DBNAME \
  --outputdir=$BCK_TARGET \
  --chunk-filesize=100 \
  --insert-ignore \
  --events \
  --triggers \
  --routines \
  --verbose 3 \
  --compress \
  --build-empty-files \
  --socket $(global_variables socket) \
  --threads=${nbproc:-"$(nproc)"} \
  --compress-protocol \
  $output_format $table_target"

time mydumper \
  --database=$DBNAME \
  --outputdir=$BCK_TARGET \
  --chunk-filesize=100 \
  --insert-ignore \
  --events \
  --triggers \
  --routines \
  --verbose 3 \
  --compress \
  --build-empty-files \
  --threads=${nbproc:-"$(nproc)"} \
  --socket $(global_variables socket) \
  --compress-protocol \
  $output_format $table_target
 lRC=$?

if [ $lRC -eq 0 ]; then
    echo "MYDUMPER BACKUP OK ..........."
else
    echo "PROBLEME MYDUMPER BACKUP"
fi

if [ "$GALERA_SUPPORT" = "1" ]; then
    info desync off
    mysql -e 'set global wsrep_desync=off'

    info etat Desynchronisation
    mysql -e 'select @@wsrep_desync'
fi

if [ $lRC -eq 0 -a -n "$KEEP_LAST_N_BACKUPS" ]; then
    info "KEEP LAST $KEEP_LAST_N_BACKUPS BACKUPS"
    ls -tp $BCK_DIR/ | grep '/$'| sort -nr | tail -n +$(($KEEP_LAST_N_BACKUPS +1)) | while IFS= read -r f; do
        echo "Removing $f";
        rm -fr $BCK_DIR/$f
    done
fi

info "Liste fichier backup"
ls -lsh $BCK_TARGET

info "BACKUP DIR: $BCK_TARGET"
info "Size: $(du -sh $BCK_TARGET| awk '{print $1}')"
info "FINAL CODE RETOUR: $lRC"
footer "LOGICAL BACKUP"
exit $lRC