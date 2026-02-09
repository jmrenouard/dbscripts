#!/bin/bash

_DIR="$(dirname "$(readlink -f "$0")")"
source $_DIR/utils.sh
alias use='psql'

## Code PostgreSQL
pg_status()
{
    local lRC=0
    $SSH_CMD pg_isready 2>&1 | grep -qiE 'accepting connections'
    lRC=$?
    if [ $lRC -eq 0 ]; then
        ok "PostgreSQL server is running ...."
        return 0
    fi
    error "PostgreSQL server is stopped ...."
    return 1
}

pgGetVal()
{
    get_val $*
}

pgSetVal()
{
    set_val $*
}

export PAGER="pspg -s 0"
alias pspg='ps -aux|head -n1 && ps -aux -f|grep postgres|grep -Ev '\''bash|su|ps|grep'\'''
alias l='ls -lsh'
alias lh='ls -lsht'
alias la='ls -lsha'
alias ii=pginfo
alias lport='netstat -ltnp'

# Cleanup all old aliases
for al in $(alias |grep -iE "(pg|psql|bdlist)_" | cut -d= -f 1 | sed -e 's/alias //g');do  
	unalias $al
done

pginstances()
{
    if [ "$1" = "all" ]; then
        pgallinstances
        return $?
    fi
    for port in $TRUSTED_PG_PORTS; do
        is tport $port
        [ $? -ne 0 ] && continue
        echo $(pgGetVal INSTANCE_NAME_$port)
    done
}
pgallinstances()
{
    local ins=$1
    local port=$(pgport $ins)
    
    for dd in /base/*; do
        lport=""
        [ -f "$dd/PG_VERSION" ] || continue
        lport=$(ls -tr1 $dd/postgresql*.conf | xargs -n 1 grep port | perl -ne '/^\s*#lport=.*$/ or print' | perl -pe 's/(.*)\s*#.*/$1/g' | perl -ne '/^\s*$/ or print' | tail -n 1 | cut -d= -f 2 | xargs -n 1)
        [ -z "$lport" ] && lport=5432
        echo "$(pgGetVal INSTANCE_NAME_$lport) "
    done
    return 0
}

_pginstances()
{ 
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(pginstances all 2>/dev/null)

    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}

for fct in pgdbs pguserdbs pgtables pgtablespk pgviews pgmatviews pgfdwinfo pgtablelines pgtableexists pgfdwservers \
pgfdwusers pgfdwreference pggenfdwreferences pgfdwrefchecks pgrefreshmatviews pgfdwref2sql pgfdwtables pgfdwtablesua pgviewsua pgmatviewsua \
pgtablesua pgtablesusa pgobjectsua pgobjectsusa pguser pguserinfo pgrouser pgrwuser pguserprivs pgrouserprivs pgrwuserprivs \
pgport pgclbackup pglbackup pglbackupglobals pgcheckbackup pgsupchecks pggennrpechecks pgupdatenrpeconf pgcounttables \
pgcountlines pgemptytables pgscountlines pgacountlines pglrestore pgdumpfdw pgflushdb pgscript pggenpublication \
pgaqueries pgbckqueries pgcancelbck pgkillbck pglockinfo pglockinginfo pglcopydb pggetinstancepaths pgtarinstance pgstartbackup \
pgstopkbackup pgschemas pgreport pgsetting pgscmd pgstatus pgstart pgrestart pgremoad pgstop pgpromote pgwarmup pgsetupslave \
pggetconf pgclongestquery pgrawpsql pgcancellastbck pgkilllastbck pgarchivexlog pgarchivewal;do
    complete -F _pginstances $fct
done


vacc_all()
{
    local lRC=0
    for ins in $(pginstances); do
        vacuumdb -U postgres -z -p $(pgport $ins) $*
        lRC=$(($lRC + $?))
    done
    return $lRC
}

pginfo_old()
{
(
	echo -e "INSTANCE\tPGDATA\tPORT\tDATA_VERSION\tRUNNING_VERSION\tSIZE\tSTATUS"
	for port in $TRUSTED_PG_PORTS; do
		is tport $port
		[ $? -ne 0 ] && continue
		ins=$(pgGetVal INSTANCE_NAME_$port)
		PGDATA=$(psql -p $port -U postgres -Ant -c "show data_directory")
		FULL_VERSION=$(eval "psql -p $port -Ant -c 'select version()'" 2>/dev/null |awk '{print $2}' )
		[ -z "$FULL_VERSION" ] && FULL_VERSION="????"
		PGSTATUS=$(pg_ctl -D $PGDATA status &>/dev/null;echo $?)
		[ $PGSTATUS != 0 ] && PGSTATUS_STR='DOWN'
		[ $PGSTATUS != 0 ] || PGSTATUS_STR='UP'
		echo -e "$ins\t$PGDATA\t$port\t$(cat $PGDATA/PG_VERSION)\t$FULL_VERSION\t$(du -sh $PGDATA| awk '{print $1}')/$( df -Ph  $PGDATA | tail -n 1 | awk '{print $2}')\t$PGSTATUS_STR"
	done
) | column -t
}

pginfo()
{
(
    echo -e "INSTANCE\tPGDATA\tPORT\tDATA_VERSION\tRUNNING_VERSION\tSIZE\tSTATUS\tROLE"
    for dd in /base/*; do
        port=""
        [ -f "$dd/PG_VERSION" ] || continue
        port=$(ls -tr1 $dd/postgresql*.conf | xargs -n 1 grep port | perl -ne '/^\s*#.*$/ or print' | perl -pe 's/(.*)\s*#.*/$1/g' | perl -ne '/^\s*$/ or print' | tail -n 1 | cut -d= -f 2 | xargs -n 1)
        [ -z "$port" ] && port=5432
        ins=$(pgGetVal INSTANCE_NAME_$port)
        is tport $port
        if [ $? -ne 0 ]; then
             PGDATA=$dd
             FULL_VERSION="UNKOWN"
             ROLE="UNKOWN"
             PGSTATUS_STR='DOWN'
        else
            PGDATA=$(psql -p $port -U postgres -Ant -c "show data_directory")
            FULL_VERSION=$(eval "psql -p $port -Ant -c 'select version()'" 2>/dev/null |awk '{print $2}' )
            PGSTATUS_STR='UP'
            ROLE=$(pggetinstancerole $ins)
        fi
        echo -e "$ins\t$PGDATA\t$port\t$(cat $PGDATA/PG_VERSION)\t$FULL_VERSION\t$(du -sh $PGDATA| awk '{print $1}')/$( df -Ph  $PGDATA | tail -n 1 | awk '{print $2}')\t$PGSTATUS_STR\t$ROLE"
    done
) | column -t
}

pgrawpsql()
{
    local ins=$1
    local port=$(pgport $ins)
    shift
    psql -p $port $ins -Ant -c "$*"
}

pggetconf()
{
    local ins=$1
    local param=$2
    local port=$(pgport $ins)
    pgrawpsql $ins "select current_setting('$param');"
}
pggetinstancerole()
{
    local ins=$1
    local PGDATA=$(pggetdatadirectory $ins)
    local is_in_recovery=$(pgrawpsql $ins 'select pg_is_in_recovery()')

    if [ "$is_in_recovery" = "t" ]; then
        local master=$(grep primary_conninfo $PGDATA/recovery.conf | grep -vE '^#' | perl -pe 's/.*host\s*=(.+?)\s.*/$1/g'| perl -pe 's/.vm.local//g')
        echo "SLAVE($master)"
        return 0
    fi
    local nbslaves=$(pgrawpsql $ins 'select count(*) from pg_stat_replication')
    if [ $nbslaves -eq 0 ]; then
        echo "STANDALONE"
        return 0
    fi
    local slaves=$(pgrawpsql $ins "select client_hostname || '/' || state || '/' || sync_state from pg_stat_replication"| perl -pe 's/\n/,/g;s/.vm.local//g')
    echo "MASTER(${nbslaves}S)-$slaves" | perl -pe 's/,$//g'
    return 0
}

pgismaster()
{
    local ins=$1
    local nbslaves=$(pgrawpsql $ins 'select count(*) from pg_stat_replication')
    if [ $nbslaves -gt 0 ]; then
        echo "1"
        return 0
    fi
    echo "0"
}
pgisslave()
{
    local ins=$1
    local PGDATA=$(pggetdatadirectory $ins)
    local is_in_recovery=$(pgrawpsql $ins 'select pg_is_in_recovery()')

    if [ "$is_in_recovery" = "t" ]; then
        echo "1"
        return 0
    fi
    echo "0"
}

pggetdatadirectory()
{
    local ins=$1
    local port=$(pgport $ins)
    
    for dd in /base/*; do
        lport=""
        [ -f "$dd/PG_VERSION" ] || continue
        lport=$(ls -tr1 $dd/postgresql*.conf | xargs -n 1 grep port | perl -ne '/^\s*#.*$/ or print' | perl -pe 's/(.*)\s*#.*/$1/g' | perl -ne '/^\s*$/ or print' | tail -n 1 | cut -d= -f 2 | xargs -n 1)
        [ -z "$port" ] && return 1
        
        if [ "$lport" = "$port" ];then
            echo $dd
            return 0
        fi
    done
    return 1
}

pgsetupallslaves()
{
    for ins in $(pginstances); do
        pgsetupslave $ins $*
    done
} 

pgsetupslave()
{
    local ins=$1
    local replhost=$2
    local repluser=${3:-"replication"}
    local replpwd=${4:-"SReplication#1234#"}

    local port=$(pgport $ins)
    local data_dirs=$(pggetinstancepaths $ins)
    PGDATA=$(pggetdatadirectory $ins)
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    banner "SETUP REPLICATION" 
    title2 "TEST CREDENTIALS TO primary host($replhost)"
    pgcheckuser $ins $ins $replhost $repluser $replpwd
    #PGPASSWORD="$replpwd" psql -p $(pgport $ins) -h $replhost -U $repluser -x $ins -c 'select 1' &>/dev/null
    if [ $? -ne 0 ];then
        warning "Wrong replication or user information for replication ...."
        return 127
    fi
    confirm "* Sauvegarde full logique de l'instance $ins"
    [ $? -ne 1 ] && [ -z "$NO_BACKUP" ] && \
      cmd "Sauvegarde full logique de l'instance $ins" "pg_dumpall -p $port --clean -f /backups/${ins}_${horodate}.full.dump"

    confirm "* Arrêt de l'instance  $ins"
    [ $? -ne 1 ] && cmd "Arrêt de l'instance  $ins" "pgstop $ins"
    
    confirm "* Etat de l'instance  $ins"
    [ $? -ne 1 ] && cmd "Etat de l'instance  $ins" "pgstatus $ins"

    confirm "* Suppression des répertoires de l'instance $ins :$(echo "$data_dirs"|xargs -n 10)"
    [ $? -ne 1 ] && for dd in $data_dirs; do
        cmd "Suppression du contenu de $dd" "rm -rf $dd/*"
    done
    confirm "* Ajout des credentials dans .pgpass"
    [ -f "$HOME/.pgpass" ] && sed -i "/:replication:/d" $HOME/.pgpass
    echo "" > $HOME/.pgpass
    echo "${replhost}:${port}:replication:${repluser}:${replpwd}" >> $HOME/.pgpass
    chmod 600 $HOME/.pgpass
    
    cmd "Fichier .pgpass" "pgdisplaysecurepgpass"

    confirm "* Synchronisation des données depuis $replhost"
    [ $? -ne 1 ] && cmd "Synchronisation des données depuis $replhost" "pg_basebackup -p$port  -h $replhost -D $PGDATA -U $repluser -X stream -P -R -c fast"

    confirm "* Remove config. parameters for replication"
    perl -i -pe 's/gssencmode=prefer //g' $PGDATA/recovery.conf
    perl -i -pe 's/recovery_target_timeline .*$//g' $PGDATA/recovery.conf
    perl -i -pe 's/trigger_file .*$//g' $PGDATA/recovery.conf
    perl -i -pe 's/application_name=.+? //g' $PGDATA/recovery.conf
    
    confirm "* Adding trigger file config. parameters for replication"
    echo "recovery_target_timeline = 'latest' 
trigger_file = '/tmp/failover_${ins}.trigger'">>$PGDATA/recovery.conf
    perl -i -pe "s/^(primary_conninfo = ')/primary_conninfo = 'application_name=$(hostname -s)_slave /g" $PGDATA/recovery.conf
    
    confirm "* Démarrage de l'instance $ins"
    [ $? -ne 1 ] && cmd "Démarrage de l'instance $ins" "pgstart $ins"

    confirm "* Status de l'instance $ins"
    [ $? -ne 1 ] && cmd "Etat de l'instance $ins" "pgstatus $ins"
    
    pgnormalmode
    cmd "Contenu du ficier recovery.conf" "cat $PGDATA/recovery.conf"
    
    title2 "$(hostname -s)/$ins IS IN RECOVERY"
    psql -p $(pgport $ins) -x $ins -c 'select pg_is_in_recovery() as is_slave_instance'

    title2 "ETAT $replhost (pg_stat_replication)"
    PGPASSWORD="$replpwd" psql -p $(pgport $ins) -h $replhost -U $repluser -x $ins -c 'select * from pg_stat_replication'
    
    footer "SETUP REPLICATION" $?
    return $?
}

pgdisplaysecurepgpass()
{
    perl -pe 's/(.*):.*?$/$1:xxxxxxxxxxxx/' $HOME/.pgpass
}

pgscmd()
{
    local ins=$1
    local cmd=${2:-"status"}
    local lRC=0
    if [ -z "$ins" ]; then
        return 127
    fi
    if [ "$ins" = "all" ]; then
        for i in $(pginstances all); do
            echo "--------------------------------"
            pgscmd $i $cmd
            lRC=$(($lRC + $?)) 
            echo "--------------------------------"
        done
        echo "FINAL RC: $lRC"
        return $lRC
    fi
    
    local port=$(pgport $ins)
    PGDATA=$(pggetdatadirectory $ins)
    echo "INSTANCE: $ins"
    echo "COMMAND: $cmd"
    echo "PGPORT: $port"
    echo "PGDATA: $PGDATA"
    /usr/pgsql-$(cat $PGDATA/PG_VERSION)/bin/pg_ctl -D $PGDATA $cmd
    lRC=$?
    echo "RETURN CODE: $lRC"
    return $lRC
}

pgstart()
{
    pgscmd $* start
}
pgstop()
{
    pgscmd $* stop
}
pgrestart()
{
    pgscmd $* restart
}
pgreload()
{
    pgscmd $* reload
}
pgpromote()
{
    pgscmd $* promote
}
pgstatus()
{
    pgscmd $* status
}

pgarchivexlog()
{
    local ins=$1
    local db=${2:-"$1"}
    local iter=${3:-"20"}
    local lRC=0
    local port=$(pgport $ins)
    local datadir=$(pggetdatadirectory $ins)
    if [ -z "$ins" ]; then
        return 127
    fi

    for i in $(seq $iter); do 
        echo "Iteration $i:";
        echo "create database dummydb;select pg_switch_xlog();drop database dummydb;" | psql -q -p $port $db
        [ $? -ne 0 ] && break
        echo "Nb WAL FILES: $(ls -1 $datadir/pg_xlog| wc -l)"
    done
}
pgarchivewal()
{
    local ins=$1
    local db=${2:-"$1"}
    local iter=${3:-"20"}
    local lRC=0
    local port=$(pgport $ins)
    local datadir=$(pggetdatadirectory $ins)
    if [ -z "$ins" ]; then
        return 127
    fi

    for i in $(seq $iter); do 
        echo "Iteration $i:";
        echo "create database dummydb;select pg_switch_wal();drop database dummydb;" | psql -q -p $port $db
        [ $? -ne 0 ] && break
        [ -d "$datadir/pg_wal" ] && echo "Nb WAL FILES: $(ls -1 $datadir/pg_wal| wc -l)"
    done
}

pgwarmup()
{
    local ins=$1
    local db=${2:-"$1"}
    local lRC=0
    if [ -z "$ins" ]; then
        return 127
    fi
    if [ "$ins" = "all" ]; then
        for i in $(pginstances all); do
            sep2
            pgwarmup $i $db
            lRC=$(($lRC + $?)) 
            sep2
        done
    else
        port=$(pgport $ins)
        for tbl in $(pgtables $ins $db); do
            info "WarmUp ${NB_LINE_MAX:-"300000"} lines of $tbl ON $db@$ins"
            echo " SELECT * from $tbl LIMIT ${NB_LINE_MAX:-"300000"};" | psql -p $port $db &>/dev/null
            lRC=$(($lRC + $?)) 
            sep2
        done
    fi
    echo "FINAL RC: $lRC"
    return $lRC
}
pgdiskinfo()
{
(
    if [ "$1" != "NOHEADER" ]; then
        echo -en "HOST\tINSTANCE\tPGDATA\t"
        echo -en "SIZE_USED_PGDATA\tSIZE_TOTAL_PGDATA\t"
        echo -en "SIZE_USED_BASE\tSIZE_TOTAL_BASE\t"
        echo -en "SIZE_USED_DATA\tSIZE_TOTAL_DATA\t"
        echo -en "SIZE_USED_WAL\tSIZE_TOTAL_WAL\t"
        echo -e "SIZE_USED_ARCHIVE\tSIZE_TOTAL_ARCHIVE\t"
    fi
    for port in $TRUSTED_PG_PORTS; do
        is tport $port
        [ $? -ne 0 ] && continue
        ins=$(pgGetVal INSTANCE_NAME_$port)
        PGDATA=$(psql -p $port -U postgres -Ant -c "show data_directory")
        SIZE_USED_PGDATA=$(du -sh $PGDATA | awk '{print $1}')
        SIZE_TOTAL_PGDATA=$( df -Ph  $PGDATA | tail -n 1 | awk '{print $2}')

        SIZE_USED_BASE=$(du -sh /base| awk '{print $1}')
        SIZE_TOTAL_BASE=$( df -Ph /base | tail -n 1 | awk '{print $2}')

        SIZE_USED_DATA=$(du -sh /data | awk '{print $1}')
        SIZE_TOTAL_DATA=$( df -Ph  /data | tail -n 1 | awk '{print $2}')
        
        SIZE_USED_WAL=$(du -sh /wal| awk '{print $1}')
        SIZE_TOTAL_WAL=$( df -Ph  /wal | tail -n 1 | awk '{print $2}')
        
        SIZE_USED_ARCHIVE=$(du -sh /archives| awk '{print $1}')
        SIZE_TOTAL_ARCHIVE=$( df -Ph  /archives | tail -n 1 | awk '{print $2}')

        echo -en "$(hostname -s)\t$ins\t$PGDATA\t"
        echo -en "$SIZE_USED_PGDATA\t$SIZE_TOTAL_PGDATA\t"
        echo -en "$SIZE_USED_BASE\t$SIZE_TOTAL_BASE\t"
        echo -en "$SIZE_USED_DATA\t$SIZE_TOTAL_DATA\t"
        echo -en "$SIZE_USED_WAL\t$SIZE_TOTAL_WAL\t"
        echo -e "$SIZE_USED_ARCHIVE\t$SIZE_TOTAL_ARCHIVE\t"
    done
) | column -t
}

psql_all()
{
    for ins in $(pginstances); do 
        echo "____________________________________________"
        echo "Running $* on $ins instance."
        echo "____________________________________________"
        $* $ins
    done
}


pgdbs()
{
	psql -p $(pgport $1) -U postgres -lAnt | grep '|' | cut -d'|' -f1 | grep -Ev 'template(0|1)'	
}

pgtables()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}

    if [ -z "$3" ]; then
        psql -p $port -Ant -c "select schemaname || '.' || tablename from pg_tables where schemaname NOT IN ('information_schema' , 'pg_catalog')" $db
    else 
        psql -p $port -Ant -c "select schemaname || '.' || tablename from pg_tables where schemaname = '$3'" $db
    fi 
}

pgtableexists()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}
    local sch=${3:-"$1"}
    local tblfile=${4:-"/admin/etc/lvg_tables.txt"}
    for tbl in $(cat ${tblfile}); do 
        nbt=$(psql -p $port -Ant -c "select count(tablename) from pg_tables where schemaname = '$sch' and tablename = '$tbl'" $db)
        echo "$tbl;$nbt"
    done
}

pgtablelines()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}
    local sch=${3:-"$1"}
    local tblfile=${4:-"/admin/etc/lvg_tables.txt"}
    for tbl in $(cat ${tblfile}); do 
        nbt=$(psql -p $port -Ant -c "select count(*) from $sch.$tbl" $db)
        echo "$tbl;$nbt"
    done
}
pgtableexport()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}
    local sch=${3:-"$1"}
    local tblfile=${4:-"/admin/etc/lvg_tables.txt"}
    local target_dir=${5:-"/backups/lvg_tables"}
    
    rm -rf $target_dir
    mkdir -p $target_dir
    rm -f ${target_dir}/truncate_all.sql
    for tbl in $(cat ${tblfile}); do 
        info "* Export table schema for $sch.$tbl WITH DROP SQL DIRECTIVES"
        pg_dump -p $port --no-acl -vsc -Fp -d $db -t $sch.$tbl > ${target_dir}/${tbl}.schema.dropnreplace.sql
        info "* Export table schema for $sch.$tbl WITHOUT  DROP SQL DIRECTIVES"
        pg_dump -p $port --no-acl -vsC -Fp -d $db -t $sch.$tbl > ${target_dir}/${tbl}.schema.create.sql
        info "* Export table data for $sch.$tbl"
        pg_dump -p $port -v --no-acl --data-only -Fp -d $db -t $sch.$tbl > ${target_dir}/${tbl}.data.sql
        echo "TRUNCATE TABLE $sch.$tbl;" >> ${target_dir}/truncate_all.sql
    done
}


pgsetting()
{
    local port=$(pgport $1)
    local key=${2:-"archive"}
    psql -p $port -Ant -c "select name, setting from pg_settings where name like '%${key}%'" | perl -pe 's/\|/\t/g' | column -t
}

pgtablespk()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}
for tbl in $(pgtables $*); do
        echo -en "$tbl\tNB_COLUMN_PK\t"
		psql -p $port -Ant $db -c "SELECT count(a) FROM   pg_index i JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = '$tbl'::regclass AND  i.indisprimary;"
        echo -en "$tbl\tCOLUMN_PK\t"
		psql -p $port -Ant $db -c "SELECT a.attname, format_type(a.atttypid, a.atttypmod) FROM  pg_index i JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = '$tbl'::regclass AND  i.indisprimary;" | tr '|' '\t'
done
}
pgviews()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}

    if [ -z "$3" ]; then
        psql -p $port -Ant -c "select schemaname || '.' || viewname from pg_views where schemaname NOT IN ('information_schema' , 'pg_catalog')" $db
    else 
        psql -p $port -Ant -c "select schemaname || '.' || viewname from pg_views where schemaname = '$3'" $db
    fi 
}

pgmatviews()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}

    if [ -z "$3" ]; then
        psql -p $port -Ant -c "select schemaname || '.' || matviewname from pg_matviews where schemaname NOT IN ('information_schema' , 'pg_catalog')" $db
    else 
        psql -p $port -Ant -c "select schemaname || '.' || matviewname from pg_matviews where schemaname = '$3'" $db
    fi 
}

pgschemas()
{
    psql -p $(pgport $1) -U postgres -Ant -c "SELECT nspname FROM pg_catalog.pg_namespace where nspname NOT IN ('information_schema') AND nspname NOT LIKE 'pg_%'" $2
    
}
pgreport()
{
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local label=${1:-"$horodate"}
    local targetDir="/admin/logs/reports/$label"
    if [ -d "$targetDir" ];then
        error "Problem $targetDir EXISTS"
        return 127
    fi
    mkdir -p /admin/logs/reports/$label

    for ins in $(pginstances); do
        mkdir -p $targetDir/$ins
        echo "$ins"
        for db in $(pguserdbs $ins); do
            mkdir  -p $targetDir/$ins/$db
            echo "$ins / $db"
            pguser $ins | sort > $targetDir/$ins/users.txt
            pguserdbs $ins | sort > $targetDir/$ins/userdbs.txt
            pgtables $ins $db | sort > $targetDir/$ins/tables.txt
            pgfdwservers $ins $db | sort > $targetDir/$ins/$db/fdwservers.txt
            pgfdwusers  $ins $db | sort > $targetDir/$ins/$db/fdwusers.txt
            for schema in $(pgschemas $ins $db); do
                mkdir -p $targetDir/$ins/$db/$schema
                echo "$ins / $db / $schema"
                pgtables $ins $db $schema | sort > $targetDir/$ins/$db/$schema/tables.txt
                pgcounttables $ins $db $schema | sort > $targetDir/$ins/$db/$schema/nbtables.txt
                pgscountlines $ins $db $schema | sort > $targetDir/$ins/$db/$schema/linetables.txt
                pgviews $ins $db $schema | sort > $targetDir/$ins/$db/$schema/views.txt
                pgmatviews $ins $db $schema | sort > $targetDir/$ins/$db/$schema/matviews.txt
                pgfdwtables $ins $db $schema | sort > $targetDir/$ins/$db/$schema/fdwtables.txt
            done
        done
    done
    find /admin/logs/reports/$label -type f | xargs -n 1 wc -l | sort
    info "Compare command: diff -rs /admin/logs/reports/$label /admin/logs/reports/<other_label>"
}

pgrefreshmatviews()
{
local port=$(pgport $1)
    local db=${2:-"$1"}
(
cat <<'EOF'
CREATE OR REPLACE VIEW mat_view_dependencies AS
WITH RECURSIVE s(start_schemaname,start_mvname,schemaname,mvname,relkind,
               mvoid,depth) AS (
-- List of mat views -- with no dependencies
SELECT n.nspname AS start_schemaname, c.relname AS start_mvname,
n.nspname AS schemaname, c.relname AS mvname, c.relkind,
c.oid AS mvoid, 0 AS depth
FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
WHERE c.relkind='m'
UNION
-- Recursively find all things depending on previous level
SELECT s.start_schemaname, s.start_mvname,
n.nspname AS schemaname, c.relname AS mvname,
c.relkind,
c.oid AS mvoid, depth+1 AS depth
FROM s
JOIN pg_depend d ON s.mvoid=d.refobjid
JOIN pg_rewrite r ON d.objid=r.oid
JOIN pg_class c ON r.ev_class=c.oid AND (c.relkind IN ('m','v'))
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE s.mvoid <> c.oid -- exclude the current MV which always depends on itself
)
SELECT * FROM s;

CREATE OR REPLACE VIEW mat_view_refresh_order AS
WITH b AS (
-- Select the highest depth of each mat view name
SELECT DISTINCT ON (schemaname,mvname) schemaname, mvname, depth
FROM mat_view_dependencies
WHERE relkind='m'
ORDER BY schemaname, mvname, depth DESC
)
-- Reorder appropriately
SELECT schemaname, mvname, depth AS refresh_order
FROM b
ORDER BY depth, schemaname, mvname
;    
    WITH a AS (
SELECT 'REFRESH MATERIALIZED VIEW "' || schemaname || '"."' || mvname || '";' AS r
FROM mat_view_refresh_order
ORDER BY refresh_order
)
SELECT string_agg(r,E'\n') AS script FROM a \gset

\echo :script
:script
EOF
) | psql -p $port $db
}

pgrefreshallmatviews()
{
    for ins in $(pginstances); do 
        echo "----------------------------------------------"
        echo "REFRESHING ALL MAT VIEWS FOR INSTANCE $ins"
        echo "----------------------------------------------"
        pgrefreshmatviews $ins $ins
        echo "----------------------------------------------"
    done
}
pgfdwinfo()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}

    echo -e "set search_path=\"$2\";\x\n\des+\n\det+\n\deu+"  | psql -p $port $db | cut -d\| -f1,2 | tr '|' '.'	
}

pgfdwservers()
{
    local ins=$1
    local db=${2:-"$1"}
    local userpatt=$3
    if [ -z "$userpatt" ]; then
        userpatt='.*'
    fi

    pgdumpfdw $ins $db | grep -v '\-\-' | \
    perl -pe "s/\(\n/\(/gm;s/,\n/, /gm;s/\'\n/\'/gm;s/^\s*$//gm;s/[ \t]{2,6}/ /g" | \
    grep -vE '(USER|OWNER TO)' | \
    perl -pe 's/CREATE SERVER (.+?) /fdwserver: $1, /g;s/FOREIGN DATA WRAPPER postgres_fdw OPTIONS \(//;s/\);//;s/,\s*/, /g' | \
    perl -pe 's/(dbname|host|port|updatable)\s/$1:/g' | \
    sed '/ sqlreq = /d' | \
    perl -pe "s/\'//g" | perl -ne "/fdwserver: $userpatt/ and print"
}

pgfdwusers()
{
    local ins=$1
    local db=${2:-"$1"}
    local userpatt=$3
    if [ -z "$userpatt" ]; then
        userpatt='.*'
    fi
    #pgrawpsql -p $(pgport $ins) $db -c "select umoptions from pg_user_mappings where "
    pgdumpfdw $ins $db | grep -v '\-\-' | \
    perl -pe "s/\(\n/\(/gm;s/,\n/, /gm;s/\'\n/\'/gm;s/^\s*$//gm;s/[ \t]{2,6}/ /g" | \
    grep -vE "(CREATE|ALTER) SERVER" | \
    perl -pe 's/CREATE USER MAPPING FOR (.+?) SERVER (.+?) OPTIONS \((.*)\);/localuser: $1, fdwserver: $2, $3/' | \
    perl -pe "s/\'//g" | perl -pe 's/\"//g' | \
    perl -pe 's/(user|password)\s/$1: /g' | \
    sed '/ sqlreq = /d' | \
    perl -pe "s/\'//g" | perl -ne "/localuser: $userpatt/ and print"
}

pgfdwreference() 
{
    local ins=$1
    local db=${2:-"$1"}
    pgfdwservers $ins $db | while IFS= read -r line
    do
        fdwsrv=$(echo $line | perl -pe 's/fdwserver: (.+?),.*/$1/')
#        echo $fdwsrv
        fdwuser=$(pgfdwusers $ins $db | grep " ${fdwsrv}," | head -n 1| cut -d, -f 3-)
#        echo $fdwuser
        echo "$line,$fdwuser" | perl -pe 's/  / /g'
    done
}

pggenfdwreferences()
{
    local refFile=""
    local instances="$*"
    [ -z "$instances" ] && instances="$(pginstances)"
    for ins in $instances; do
        for db in $(pgdbs $ins| grep -vE '(postgres|to_del|_old|2019|2020|2021)'); do
            refFile="/admin/etc/fdwdefinition_${ins}_${db}.data"
            echo "Ref File: $refFile"
            #[ -f "$refFile" ] && [ -z "$FORCE" ] &&  continue
            rm -f $refFile
            pgfdwreference $ins $db | tee -a $refFile
            echo "---------------------------------------"
        done
    done
}

pgfdwrefchecks()
{
    while IFS= read -r line; do
        #echo $line
        #echo $line | perl -pe 's/\: /:/g;s/:/=/g;s/,/\n/g;s/ //g'
        unset user password host port dbname fdwserver
        for data in $(echo $line| perl -pe 's/\: /:/g;s/:/=/g;s/,/\n/g;s/ //g'); do
            eval "$(echo $data)"
        done
        for vari in user password host port dbname fdwserver; do
            if [ -z "$(pgGetVal $vari)" ]; then
                error "In line $line"
                error "$vari IS NOT DEFINED..."
                return 127
            fi
        done
        echo -n "-- $(basename $1) - Testing Access $fdwserver - $host - $dbname - $port - $password - $user"
        #set -x
        PGPASSWORD="$password" timeout 1s psql -h $host -p $port -U $user $dbname -c 'select 1' &>/dev/null
        if [ $? -eq 0 ]; then
            echo "[OK]"
        else
            echo "[FAILURE]"
        fi
    done < $1
}

pgfdwrefallchecks()
{
    for refFile in /admin/etc/fdwdefinition_*.data; do 
        echo "$f"
        echo '-------------------------------------------------------'
        pgfdwrefchecks $refFile
    done
}

pginjectfdwdef()
{
    local instances="$*"
    [ -z "$instances" ] && instances="$(pginstances)"
    for ins in $instances; do
        [ -f "/admin/etc/fdwdefinition_${ins}_${ins}.data" ] || continue
        pgfdwref2sql /admin/etc/fdwdefinition_${ins}_${ins}.data | psql -p $(pgport $ins) $ins
    done
}
pgfdwref2sql()
{
    local refFile=${1}
    while IFS= read -r line; do
        unset user password host port dbname fdwserver
        for data in $(echo $line| perl -pe 's/\: /:/g;s/:/=/g;s/,/\n/g;s/ //g'); do
            eval "$(echo $data)"
        done
        for vari in user password host port dbname fdwserver; do
            if [ -z "$(pgGetVal $vari)" ]; then
                error "In line $line"
                error "$vari IS NOT DEFINED..."
                return 127
            fi
        done
       echo "DROP FUNCTION IF EXISTS fdwsetup_${fdwserver}(int);

CREATE FUNCTION public.fdwsetup_${fdwserver}(int)
RETURNS INTEGER AS \$\$
DECLARE 
    i integer;
    userrow RECORD;
    sqlreq  TEXT;
BEGIN 
i:=0;
-- $fdwserver - $host - $dbname - $port - $password - $user
PERFORM 1 FROM pg_catalog.pg_foreign_server WHERE srvname='$fdwserver';
sqlreq='';
IF FOUND THEN
   sqlreq = 'ALTER SERVER $fdwserver OPTIONS ( SET host ''$host'', SET dbname ''$dbname'', SET port ''$port'');';
   RAISE NOTICE 'SQL EXECUTE: %', sqlreq;
   i:= i+1;
ELSE
    sqlreq = 'CREATE SERVER $fdwserver FOREIGN DATA WRAPPER postgres_fdw OPTIONS ( host ''$host'', dbname ''$dbname'', port ''$port'', updatable: ''false'');';
    RAISE NOTICE 'SQL EXECUTE: %', sqlreq;
    i:= i+1;
    sqlreq = 'ALTER SERVER $fdwserver OWNER TO postgres;';
    RAISE NOTICE 'SQL STATEMENT: %', sqlreq;
    i:= i+1;
END IF;
IF \$1 = 1 THEN
    RAISE NOTICE 'EXECUTE SQL: %', sqlreq;
    EXECUTE sqlreq;
END IF;
-- Managing user mapping
FOR userrow IN
   SELECT usename FROM pg_catalog.pg_user where usename NOT IN ('check_pgactivity', 'check_activity', 'replication', 'lreplication', 'sreplication')
LOOP
    PERFORM 1 FROM pg_catalog.pg_user_mappings WHERE srvname='$fdwserver'AND usename = userrow.usename;
    IF FOUND THEN
        sqlreq = 'ALTER USER MAPPING FOR \"' || userrow.usename || '\" SERVER $fdwserver OPTIONS ( SET user ''$user'', SET password  ''$password'');';
    ELSE
        sqlreq = 'CREATE USER MAPPING FOR \"' || userrow.usename || '\" SERVER $fdwserver OPTIONS ( user ''$user'', password ''$password'');';
    END IF;
    RAISE NOTICE 'SQL STATEMENT: %', sqlreq;
    IF \$1 = 1 THEN
        RAISE NOTICE 'EXECUTE SQL: %', sqlreq;
        EXECUTE sqlreq;
    END IF;
    i:= i+1;
END LOOP;
return i;
END;
\$\$
LANGUAGE plpgsql;
select fdwsetup_${fdwserver}(1);"
    done < $refFile
}

pgfdwtables()
{
    local port=$(pgport $1)
    local db=${2:-"$1"}

    echo -e "set search_path=\"${db}\";\n\det" | psql -p $port -Ant $db | cut -d\| -f1,2 | tr '|' '.' | grep -vE '^SET$'
}

pgfdwtablesua()
{
	local user=$1
	local lRC=0
    shift

	for tbl in $(pgfdwtables $@); do
		psql -p $(pgport $1) -U $user -Ant -c "SELECT * FROM ${tbl} LIMIT 1;" ${2:-"$1"} &>/dev/null
		if [ $? -eq 0 ]; then
			[ "$SILENT" != "1" ] && echo -e "FDTABALE\t$user\t$tbl\tOK"
		else
			echo -e "FDTABALE\t$user\t$tbl\tFAIL"
            lRC=$(($lRC + 1))
        fi
	done
    return $lRC
}

pgviewsua()
{
	local user=$1
    local lRC=0
	shift
	for tbl in $(pgviews $@); do
		psql -p $(pgport $1) -U $user -Ant -c "SELECT * FROM ${tbl} LIMIT 1;" ${2:-"$1"} &>/dev/null
		if [ $? -eq 0 ]; then
			[ "$SILENT" != "1" ] && echo -e "VIEW\t$user\t$tbl\tOK"
		else
			echo -e "VIEW\t$user\t$tbl\tFAIL"
            lRC=$(($lRC + 1))
        fi
	done
    return $lRC
}

pgmatviewsua()
{
	local user=$1
    local lRC=0
	shift
	for tbl in $(pgmatviews $@); do
		psql -p $(pgport $1) -U $user -Ant -c "SELECT * FROM  ${tbl} LIMIT 1;" ${2:-"$1"} &>/dev/null
		if [ $? -eq 0 ]; then
			[ "$SILENT" != "1" ] && echo -e "MATVIEW\t$user\t$tbl\tOK"
		else
			echo -e "MATVIEW\t$user\t$tbl\tFAIL"
            lRC=$(($lRC + 1))
        fi
	done
    return $lRC
}

pgtablesua()
{
	local user=$1
    local lRC=0
	shift
	for tbl in $(pgtables $@); do
		psql -p $(pgport $1) -U $user -Ant -c "SELECT * FROM ${tbl} LIMIT 1;" ${2:-"$1"} &>/dev/null
		if [ $? -eq 0 ]; then
			[ "$SILENT" != "1" ] && echo -e "TABLE\t$user\t$tbl\tOK"
		else
			echo -e "TABLE\t$user\t$tbl\tFAIL"
            lRC=$(($lRC + 1))
        fi
	done
    return $lRC
}

pgtablesusa()
{
    local lRC=0
	for u in $(pguser $1); do 
		pgtablesua $u $1 ${2:-"$1"}
        lRC=$(($lRC + $?))
	done
    return $lRC
}

pgobjectsua()
{
    local lRC=0
    pgtablesua $@
    lRC=$(($lRC + $?))
	pgviewsua $@
    lRC=$(($lRC + $?))
	pgmatviewsua $@
    lRC=$(($lRC + $?))
	pgfdwtablesua $@
    lRC=$(($lRC + $?))
    return $lRC
}

pgobjectsusa()
{
    local lRC=0
	for u in $(pguser $1); do 
		pgobjectsua $u $1 ${2:-"$1"}
        lRC=$(($lRC + $?))
	done
    return $lRC
}

pgcheckuseraccess()
{
    local lRC=0
    local instances=$*
    [ -z "$instances" ] && instances="$(pginstances)"
    for ins in $instances; do 
        echo "----------------------------------------------"
        echo "REJECTED ACCESS FOR INSTANCE $ins"
        echo "----------------------------------------------"
        SILENT=1 pgobjectsusa $ins $ins
        lRC=$(($lRC + $?))
        echo "----------------------------------------------"
    done
    return $lRC
}

pguserdbs()
{
    psql -p $(pgport $1) -U postgres -lAnt | grep '|' | cut -d'|' -f1 | grep -Ev 'postgres|template(0|1)'
}

pguserinfo()
{
(
echo -e "INSTANCE\tBASE\tUTILISATEUR\tPRIVILEGES"
for ins in $*; do
        port=$(pgport $ins)
        for PGDB in $(psql -p $port -Ant -c "select datname from pg_database where datname NOT in( 'template1', 'template0', 'postgres' );" 2>/dev/null| sort); do
                for pguser in $(psql -p $port -Ant -c "select usename from pg_user ;" $PGDB 2>/dev/null| sort |xargs); do
                        PRIVS=$(psql -p $port -Ant -c "select distinct(privilege_type) from information_schema.table_privileges where grantee = '${pguser}'" $PGDB 2>/dev/null| perl -pe 's/\n/\//g;s/ +//g'| sort | perl -pe 's/\/$//')
                        [ -z "$PRIVS" ] && PRIVS="PAS_DE_DROIT"
                        echo -e "${ins}\t${DBNAME}\t${PGDB}\t${pguser}\t${PRIVS}"
                done
        done
done
) | column -t
}

pgcreateuser()
{
    local ins=$1
    local db=$2
    local username=$3
    local type=$4
    local pass="$(pwgen -1 16)"
    local lRC=0
    title2 "PG USER CREATION: $username/$type@$ins:$db"
    create_role.py $username --instance $ins --schema=$db --grant=$type --client-ips=0.0.0.0 --input-json="{ \"user_password\": \"$pass\" }"
    lRC=$?
    if [ $lRC -ne 0 ]; then
        error "Error occured during user $username/$type@$ins:$db creation with $pass"
        error "USER CREATION FAILED"
        return 1
    fi
    info "USER $username/$type@$ins:$db CREATED"
    info "PLEASE NOTE FOLLOWING PASSWORD (PAS DE SOLUTION DE RECUPERATION DE MOT PASSE)"
    info "password: $pass"
    ok "USER CREATION OK"

    title2 "TESTING REMOTE ACCESS $username/$type@$ins:$db"
    info "cmd: pgcheckuser $ins $db local $username $pass"
    pgcheckuser $ins $db local $username $pass
    lRC=$?
    if [ $lRC -ne 0 ];then
        error "Test connexion for $username/$type@$ins:$db FAILED"
        return 2
    fi
    ok "USER ACCESS WITH PASSWORD OK"

    title2 "SETUP FOREIGN DATA WRAPPER CREDENTIALS FOR $username"
    
    pgfdwreference $ins $ins > /admin/etc/fdwdefinition_${ins}_${ins}.data
    pginjectfdwdef $ins &>>/dev/null
    lRC=$?
    if [ $lRC -ne 0 ];then
        error "($lRC)Reinject user mappings FAILED"
        return 3
    fi
    ok "SETUP FOREIGN DATA WRAPPER CREDENTIALS FOR $username"
    title2 "ADDING PRIVILEGES ON $db@$ins To $username"
    case "$type" in
        "ro")
            pgrouserprivs $ins $db $db $username | psql -q -p $(pgport $ins) $db
            ;;
        "rw")
            pgrwuserprivs $ins $db $db $username | psql -q -p $(pgport $ins) $db
            ;;
        "all")
            pgalluserprivs $ins $db $db $username | psql -q -p $(pgport $ins) $db
            ;;
        *)
            error "UNKNOWN type $type"
            ;;
    esac
    lRC=$?
    if [ $lRC -ne 0 ];then
        error "($lRC)ADDING PRIVILEGES ON $db@$ins To $username"
        return 3
    fi
    
    title2 "TEST REJECTED ALL OBJECT ACCESS FOR $username/$type@$ins:$db"
    info "cmd: SILENT=1 pgobjectsua $username $ins $db"
    SILENT=1 pgobjectsua $username $ins $db
    lRC=$?
    if [ $lRC -ne 0 ];then
        error "($lRC)Test table access for $username/$type@$ins:$db FAILED"
        return 3
    fi
    info "USER $username/$type@$ins:$db CREATED"
    info "PLEASE NOTE FOLLOWING PASSWORD (PAS DE SOLUTION DE RECUPERATION DE MOT PASSE)"
    info "password: $pass"
    ok "ALL IS OK: USER CREATION FOR $username/$type@$ins:$db"
    return 0
}

pgchangeuserpwd()
{
    local ins=$1
    local db=$2
    local user=$3
    local pass=${4:-"$(pwgen -1 16)"}

    title1 "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL"
    cmd "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL" "psql -p$(pgport $ins) -c \"ALTER USER $user WITH PASSWORD '$pass'\""
    footer "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL"
    
    title2 "TESTING REMOTE ACCESS $user/$type@$ins:$db"
    info "cmd: pgcheckuser $ins $db local $user $pass"
    pgcheckuser $ins $db local $user $pass
    lRC=$?
    if [ $lRC -ne 0 ];then
        error "Test connexion for $user/$type@$ins:$db FAILED"
        return 2
    fi
    info "password for $user@$ins is: $pass"
    ok "USER ACCESS WITH PASSWORD OK"
    return 0
}
pgdropuser()
{
    local ins=$1
    local username=$2
    local lRC=0

    title2 "PG USER MAPPING DELETION: $username@$ins"
    for srv in $(pgfdwservers produit | perl -pe 's/.*\s(.+?fdw),.*/$1/g'); do
        echo "DROP USER MAPPING IF EXISTS FOR $username SERVER $srv;"
    done | psql -p $(pgport $ins) $ins
    lRC=$?
    if [ $lRC -ne 0 ]; then
        error "Error occured during user mapping deletion $username@$ins deletion"
        error "USER DELETION FAILED"
        return 1
    fi
    ok "USER MAPPING DELETION OK"

    title2 "PG USER DELETION: $username@$ins"
    drop_role.py $username --force --instance $ins
    lRC=$?
    if [ $lRC -ne 0 ]; then
        error "Error occured during user $username/$type@$ins:$db deletion"
        error "USER DELETION FAILED"
        return 1
    fi
    ok "USER DELETION OK"

    title2 "TESTING  $username@$ins DOESNT EXIST"
    info "cmd: pguser $ins"
    pguser $ins
    pguser $ins | grep -E "^$username\$"
    lRC=$?
    if [ $lRC -eq 0 ];then
        error "Test USER DOESNT EXIST for $username@$ins FAILED"
        return 2
    fi
    ok "ALL IS OK: USER DELETION FOR $username@$ins"
    return 0
}

pgchangeuserpwd()
{
    local ins=$1
    local user=$2
    local pass=${3:-"$(pwgen -1 16)"}

    title1 "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL"
    cmd "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL" "psql -p$(pgport $ins) -c \"ALTER USER $user WITH PASSWORD '$pass'\""
    footer "CHANGING PASSORD FOR USER $user ON $ins PostgreSQL"
    [ -z "$3" ] && info "password for $user@$ins is: $pass"
}

pgchangealluserspwd()
{
    local user=$1
    local pass=${2:-"$(pwgen -1 16)"}

    for ins in $(pginstances); do
        pgchangeuserpwd $ins $user $pass
    done
    [ -z "$2" ] && info "password for $user@$ins is: $pass"
}

pgcheckuser()
{
    local ins=$1
    local db=$2
    local pghost=$3
    local pguser=$4
    local pgpass=$5
    local lRC=0
    [ "$pghost" = "local" ] && pghost=$(hostname -s)
    PGPASSWORD="$pgpass" psql -p $(pgport $ins) -h $pghost -U $pguser -x $db -c 'select 1' &>/dev/null
    lRC=$?
    if [ $lRC -eq 0 ]; then
        ok "* ACCESS $pguser@$pghost($ins-$(pgport $ins)):$db"
    else
        error "* ACCESS $pguser@$pghost($ins-$(pgport $ins)):$db FAILED"
    fi
    return $lRC
}

pgcheckuserinstances()
{
    local pghost=$1
    local pguser=$2
    local pgpass=$3
    local lRC=0
    local fRC=0
    for ins in $(pginstances); do
        PGPASSWORD="$pgpass" psql -p $(pgport $ins) -h $pghost -U $pguser -x $db -c 'select 1' &>/dev/null
        lRC=$?
        fRC=$(($lRC + $?))
        if [ $lRC -eq 0 ]; then
            ok "* ACCESS $pguser@$pghost($ins-$(pgport $ins)):$db"
        else
            error "* ACCESS $pguser@$pghost($ins-$(pgport $ins)):$db FAILED"
        fi
    done
    return $fRC
}
pguser()
{
	local port=$(pgport $1)
	psql -p $port -Ant -c "SELECT usename from pg_user where usename not in ('postgres', 'replication', 'lreplication', 'sreplication', 'check_pgactivity')"
}

pgrouser()
{
    local port=$(pgport $1)
    psql -p $port -Ant -c "SELECT usename from pg_user where usename not in ('postgres', 'replication', 'lreplication', 'sreplication', 'check_pgactivity')"  | grep -vE "(rw)" | grep -vE "^${ins}$"
}

pgrwuser()
{
	local port=$(pgport $1)
	psql -p $port -Ant -c "SELECT usename from pg_user where usename not in ('postgres', 'replication', 'lreplication', 'sreplication', 'check_pgactivity')" | grep -E "(rw|$1|ref)" | grep -vE 'ro$'
}

pgcheckuserpwd()
{
    local port=$(pgport $1)
    local user=$2
    local pass=$3
    PGPASSWORD="$pass" psql -p $port -h $(hostname -s) -U $user -Ant -c "SELECT 1" $1 &>/dev/null
    if [ $? -eq 0 ]; then
        echo "ACCES OK FOR $user ON INSTANCE $1"
        return 0
    fi
    echo "ACCES FAIL FOR $user ON INSTANCE $1"
    return 1
}

pgrenamedb()
{
    local db=$1
	local newdb=${2:-"${db}_rescue_$(date +%d%m%y_%H_%M)"}
    local tmpFile=$(mktemp)
    local lRC=0
	(  echo "DROP DATABASE IF EXISTS ${newdb};"
        echo "BEGIN TRANSACTION;" 
    echo "SELECT * FROM pg_stat_activity WHERE datname = '${db}';
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${db}';
ALTER DATABASE ${db} RENAME TO ${newdb};
COMMIT;") >> $tmpFile 

    cat $tmpFile
    if [ -n "$target" ]; then
      psql -ea -p $(pgport $target) < $tmpFile
    fi
    lRC=$?
    rm -f $tmpFile
    return $?
}

pggetcreatedb()
{
    local ins=$1
    local db=$2
    [ -z "$db" ] && db=$1
    pg_dump -p $(pgport $ins) $db -sC | grep -B4 -A 3 "CREATE DATABASE" | perl -ne '/^\s*$/ or print'
}

pggetglobals()
{

    local ins=$1
    pg_dumpall -p $(pgport ${ins}) -g
}

pgcopyinstancedb()
{
    local sins=$1
    local tins=$2
    local db=$3
    [ -z "$db" ] && db=$1
    local lRC=0

    banner "COPYING DATABASE $db FROM INSTANCE $sins TO $tins"

    pgdbs $sins | grep -Eq "^${db}$"
    if [ $? -ne 0 ]; then
        error "SOURCE DB $db doesnt exist"
        return 1
    fi
    pgdbs $tins | grep -Eq "^${db}$"
    if [ $? -eq 0 ]; then
        warn "TARGET DB $db exists"
        #return 2
    fi
    confirm "Start copy ?"
    cmd "COPYING GLOBALS DATA" "pggetglobals $sins | psql -abe -p $(pgport $tins)"

    cmd "DROPPING TARGET DATABASE IF EXISTS $db in $tins" "psql -abe -p $(pgport $tins) -c 'DROP DATABASE IF EXISTS $db;'"

    #cmd "CREATE DATABASE $db INTO Target instance: $tins" "pggetcreatedb $sins $db | psql -abe -p $(pgport $tins)"
    #lRC=$(($lRC + $?))
    #[ $lRC -ne 0 ] &&  return 3

    cmd "COPYING DATABASE $db@$sins DATA(s) INTO Target instance: $tins" "pg_dump -p $(pgport ${sins}) -bCo  $db | psql -q -p $(pgport $tins)"
    lRC=$(($lRC + $?))
    [ $lRC -ne 0 ] &&  return 3

    cmd "Remise en place des droits" "pguserprivs $tins $db $db | psql -p $(pgport $tins) $db"
    lRC=$(($lRC + $?))
    [ $lRC -ne 0 ] &&  return 3

    cmd "Analyse des données de stat." "vacuumdb -p $(pgport $tins) -az"
    lRC=$(($lRC + $?))
    [ $lRC -ne 0 ] &&  return 3

    footer "COPYING DATABASE $db FROM INSTANCE $sins TO $tins"
}


pgswitchnewdb()
{
    local ins=$1
    local db=${2:-"$ins"}
    local doit="${3}"
    local tmpFile=$(mktemp)
    pgrenamedb $db > $tmpFile
    pggetcreatedb $ins $db >> $tmpFile

    cat $tmpFile
    [ "$doit" = "go" ] && psql -ea -p $(pgport $ins) < $tmpFile
}

pggetcrontabpgback()
{
    local ins=$1
    if [ -z "$1" -o "$ins" = "all" ]; then
        for ins in $(pginstances); do
            pggetcrontabpgback $ins
            lRC=$(($lRC + $?))
        done
        return $lRC
    fi
    crontab -l| grep $ins | grep pg_back | perl -pe 's/.*?(pg_back)/$1/;s/\&.*$//' | sort | uniq
}

pgrunpgback()
{
    local ins=$1
    local lRC=0
    if [ -z "$1" -o "$ins" = "all" ]; then
        for ins in $(pginstances); do
            pgrunpgback $ins
            lRC=$(($lRC + $?))
        done
        return $lRC
    fi
    cmd=$(pggetcrontabpgback $ins)
    
    cmd "SAUVEGARDE DE L'INSTANCE $ins" "$cmd"
    return $?
}
pguserprivs()
{
	pgrouserprivs $@
	pgrwuserprivs $@
}

pgrouserprivs()
{
	local ins=$1
	local db=$2
	[ -z "$db" ] && db=$1
	local schema=$3
	[ -z "$schema" ] && schema=$1
	local users=$4
	[ -z "$users" ] && users=$(pgrouser $ins)
	for user in $users; do
		echo "--
-- ADDING READ ONLY PRIVILEGES FOR USER ${user} ON DATABASE ${db} AND SCHEMA ${schema}
--
GRANT CONNECT ON DATABASE ${db} TO \"${user}\";
GRANT USAGE ON SCHEMA ${schema} TO  \"${user}\";
GRANT USAGE ON SCHEMA public TO \"${user}\";
GRANT USAGE ON SCHEMA information_schema TO  \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA ${schema} TO \"${user}\";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${schema} TO \"${user}\";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ${schema} TO \"${user}\";
ALTER ROLE \"${user}\" IN DATABASE ${db} SET search_path = \"\$user\", ${schema}, public, information_schema;
ALTER DEFAULT PRIVILEGES IN SCHEMA PUBLIC GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA information_schema GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT EXECUTE ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT USAGE, SELECT ON SEQUENCES TO \"${user}\";
--
"
	done
}

pgalluserprivs()
{
    local ins=$1
    local db=$2
    [ -z "$db" ] && db=$1
    local schema=$3
    [ -z "$schema" ] && schema=$1
    local users=$4
    [ -z "$users" ] && users=$ins
    for user in $users; do
        echo "--
-- ADDING ALL PRIVILEGES FOR USER ${user} ON DATABASE ${db} AND SCHEMA ${schema}
--
GRANT ALL ON DATABASE ${db} TO \"${user}\";
GRANT ALL ON SCHEMA ${schema} TO  \"${user}\";
GRANT USAGE ON SCHEMA public TO \"${user}\";
GRANT USAGE ON SCHEMA information_schema TO  \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO \"${user}\";
GRANT ALL ON ALL TABLES IN SCHEMA ${schema} TO \"${user}\";
GRANT ALL ON ALL SEQUENCES IN SCHEMA ${schema} TO \"${user}\";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA ${schema} TO \"${user}\";
ALTER ROLE \"${user}\" IN DATABASE ${db} SET search_path = \"\$user\", ${schema}, public, information_schema;
ALTER DEFAULT PRIVILEGES IN SCHEMA PUBLIC GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA information_schema GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT ALL ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT ALL ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT ALL ON SEQUENCES TO \"${user}\";
--
"
    done
}

pgrwuserprivs()
{
	local ins=$1
	local db=$2
	[ -z "$db" ] && db=$1
	local schema=$3
	[ -z "$schema" ] && schema=$1
	local users=$4
	[ -z "$users" ] && users=$(pgrwuser $ins)

	for user in $users; do
		echo "--
-- ADDING READ/WRITE PRIVILEGES FOR USER ${user} ON DATABASE ${db} AND SCHEMA ${schema}
--
GRANT CONNECT ON DATABASE ${db} TO \"${user}\";
GRANT USAGE ON SCHEMA public TO \"${user}\";
GRANT USAGE ON SCHEMA ${schema} TO \"${user}\";
GRANT USAGE ON SCHEMA information_schema TO  \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO \"${user}\";
GRANT SELECT ON ALL TABLES IN SCHEMA INFORMATION_SCHEMA  TO \"${user}\";
GRANT ALL ON ALL TABLES IN SCHEMA ${schema} TO \"${user}\";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${schema} TO \"${user}\";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ${schema} TO \"${user}\";
ALTER ROLE \"${user}\" IN DATABASE ${db} SET search_path = \"\$user\", ${schema}, public, information_schema;
ALTER DEFAULT PRIVILEGES IN SCHEMA PUBLIC GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA information_schema GRANT SELECT ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT EXECUTE ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO \"${user}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema} GRANT USAGE, SELECT ON SEQUENCES TO \"${user}\";
--
"
	done
}

genFdwDescription()
{
    local confFile=${1:-"/admin/etc/foreigndatawrapper.tsv"}
    if [ ! -f "$confFile" ]; then
        echo "$confFile DOES NOT EXIST"
        return 2
    fi
}

genFdwUser()
{

for u in $(pguser $@); do
        echo  "CREATE USER MAPPING FOR \"$u\" SERVER  backendfdw  OPTIONS (user '$u', password '$p' );"
        echo  "ALTER USER MAPPING FOR \"$u\" SERVER  backendfdw  OPTIONS (SET user '$u', SET password '$p' );"
done
}

importFdwTable()
{
	echo "IMPORT FOREIGN SCHEMA $schema LIMIT TO ( $table ) FROM SERVER backendfdw INTO public;
ALTER FOREIGN TABLE public.$table RENAME TO $db;
ALTER FOREIGN TABLE public.$table SET SCHEMA $schema;"
}

pgport()
{
	local port=0
	is number $1
	if [ $? -eq 0 ];then
		echo $1
		return 0
	fi

	port=$(env | grep INSTANCE_NAME_ | grep -E "$1$" | cut -d= -f1 | cut -d_ -f3)
	[ -z "$port" ] && port=5432
	echo $port
}

pglbackupall()
{
	local ins=${1:-""}
	local target_dir=${2:-"/backups/$ins/"}
	local hordate=$(date "+%Y-%m-%d_%H-%M-%S")
	local RC=0
	for db in $(pgdbs $ins); do
		pglbackup $ins $db $target_dir 
		RC=$(($RC + $?))
	done
	return $RC
}


pgclbackup()
{
	local target_dir=${3:-"/backups/$ins/"}

	pglbackupglobals $1 $3
	[ "$?" -eq "0" ] || return 1
	pglbackup $1 $2 $3
	[ "$?" -eq "0" ] || return 1

	echo "--------------------------"
	echo "Check"
	echo "--------------------------"
	ls -lsh $target_dir
}

pglbackupall() 
{
	for ins in /base/*; do  
		ins=$(basename $ins)
		echo "# $ins"
		echo "mkdir -p /backups/${ins}_04072019"
		echo "pgclbackup $ins $(echo $ins| cut -d_ -f1) /backups/${ins}_04072019"
	 done
}

pglbackup()
{
	#set -x
	local ins=${1:-""}
	local db=${2:-"$ins"}
	local target_dir=${3:-"/backups/export_$ins/"}
	local bckformat=${4:-"plain"}
	local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local log_file=${LOG_FILE:-"$target_dir/export_${db}_${horodate}.log"}
    [ -z "$LOG_FILE" ] && LOG_FILE=$log_file
	local RC=255
	if [ -z "$ins" ]; then
		error "NO INSTANCE"
		return 255
	fi
	if [ -z "$db" ]; then
		error "NO DB"
		return 255
	fi
	if [ ! -d "$target_dir" ]; then
		info "* creating backup dir."
		mkdir -p $target_dir
	fi

	info "Sauvegarde de la base $db pour l'instance PostgreSQL ${ins}"
	info "pg_dump -p $(pgport ${ins}) --format=${bckformat} --no-acl -v -C $db > $target_dir/export_${db}_${horodate}.${bckformat}.dump 2>$log_file"
	pg_dump -p $(pgport ${ins}) --format=${bckformat} --no-acl -v -C $db > $target_dir/export_${db}_${horodate}.${bckformat}.dump 2>$log_file
	RC=$?
	info "Fin de sauvegarde de la base $db pour l'instance PostgreSQL ${ins}"
	info "STATUS SAUVEGARDE: $RC"
	chmod 660 $target_dir/*

	info "Analyse du fichier de log: $log_file"
	nb_errors=$(grep -cE '(error|warn)' $log_file)
	grep -E '(error|warn)' $log_file
	info "Fin d'analyse du fichier de log: $log_file"
	info "NB ERREUR DANS LES LOG: $nb_errors"
	RC=$(($RC + $nb_errors))
    export last_export_file="$target_dir/export_${db}_${horodate}.${bckformat}.dump"
	#set +x
	return $RC
}

pgltablebackup()
{
    #set -x
    local ins=${1:-""}
    local db=${2:-"$ins"}
    local tables=${3:-'*'}
    local target_dir=${4:-"/backups/export_$ins/"}
    local bckformat=${5:-"plain"}
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local log_file=${LOG_FILE:-"$target_dir/export_${db}_${horodate}.log"}
    [ -z "$LOG_FILE" ] && LOG_FILE=$log_file
    local RC=0
    if [ -z "$ins" ]; then
        error "NO INSTANCE"
        return 255
    fi
    if [ -z "$db" ]; then
        error "NO DB"
        return 255
    fi
    if [ -z "$tables" ]; then
        error "NO DB"
        return 255
    fi
    if [ ! -d "$target_dir" ]; then
        info "* creating backup dir."
        mkdir -p $target_dir
    else 
        rm -f $target_dir/*
    fi
    echo "" > $logfile
    for table in $(pgtables $ins $db| grep -E "$tables"); do
        [ $RC -ne 0 ] && continue
        info "* Sauvegarde de la table $table de la base $db pour l'instance PostgreSQL ${ins}"| tee -a $logfile
        info "pg_dump -p $(pgport ${ins}) --format=${bckformat} --table $table --no-acl -v -C $db > $target_dir/export_${db}_${table}_${horodate}.${bckformat}.dump 2>>$log_file"
        pg_dump -p $(pgport ${ins}) --format=${bckformat} --table $table --no-acl -v -C $db > $target_dir/export_${db}_${table}_${horodate}.${bckformat}.dump 2>>$log_file
        RC=$(($RC + $?))
        info "* Sauvegarde de la table $table de la base $db pour l'instance PostgreSQL ${ins} ($RC)[DONE]"
        info '================================================================================================' | tee -a $logfile

    done
    info "Fin de sauvegarde des tables $tables de la base $db pour l'instance PostgreSQL ${ins}"
    info "STATUS SAUVEGARDE: $RC"
    [ $RC -ne 0 ] && cat $logfile
    chmod 660 $target_dir/*

    info "Analyse du fichier de log: $log_file"
    nb_errors=$(grep -cE '(error|warn)' $log_file)
    grep -E '(error|warn)' $log_file
    info "Fin d'analyse du fichier de log: $log_file"
    info "NB ERREUR DANS LES LOG: $nb_errors"
    RC=$(($RC + $nb_errors))
    ls -lsh $target_dir
    return $RC
}
pgimporttable()
{
    local ins=$1
    local db=$2
    shift;shift
    local out="stdout"
    if [ ! -f "$1" ]; then
        out="$1"
        shift
    fi
    if [ "$out" = "psql" ]; then
        perl -pe "s/(CREATE TABLE (.*?)\.(.*?) \()/ALTER TABLE \$2\.\$3 RENAME TO \$3_$(date +%d%m%y_%H_%M);\n\$1/" $* | psql -ea -p $(pgport $ins) $db
        return $?
    fi
    perl -pe "s/(CREATE TABLE (.*?)\.(.*?) \()/ALTER TABLE \$2\.\$3 RENAME TO \$3_$(date +%d%m%y_%H_%M);\n\$1/" $*
    return $?
}

pglbackupglobals()
{
	local ins=${1:-""}
	local target_dir=${2:-"/backups/$ins/"}
	local db=postgres
	local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
	local RC=255
	if [ -z "$ins" ]; then
		echo "NO INSTANCE"
		return 255
	fi
	if [ -z "$db" ]; then
		echo "NO DB"
		return 255
	fi
	if [ ! -d "$target_dir" ]; then
		echo "* creating backup dir."
		mkdir -p $target_dir
	fi

	info "Sauvegarde des droits globaux pour l'instance PostgreSQL ${ins} "
	pg_dumpall -p $(pgport ${ins}) -v -g > $target_dir/backup_${ins}_globals_${horodate}.dump 2>$target_dir/backup_${ins}_globals_${horodate}.log
	RC=$?
	info "Fin de sauvegarde des droits globaux pour l'instance PostgreSQL ${ins}"
	info "STATUS SAUVEGARDE: $RC"
	
	info "Analyse du fichier de log: $target_dir/backup_${ins}_globals_${horodate}.log"
	nb_errors=$(grep -cE '(error|warn)' $target_dir/backup_${ins}_globals_${horodate}.log)
	grep -E '(error|warn)' $target_dir/backup_${ins}_globals_${horodate}.log
	info "Fin d'analyse du fichier de log: /$target_dir/backup_${ins}_globals_${horodate}.log"
	info "NB ERREUR DANS LES LOG: $nb_errors"
	RC=$(($RC + $nb_errors))
	return $RC
}

pgcheckbackup()
{
    local ins=${1:-""}
    local db=${2:-"$ins"}
    local maxFile=${3:-"2"}
    is user postgres 
    [ $? -eq 0 ] || return 127
    local tmpFile=$(mktemp)
     dbname=$ins
            echo $ins | grep -q generic
            if [ $? -eq 0 ]; then
                dbname=$(pgdbs $ins| grep -vE  '(postgres|to_del|_old|2019|2020|2021)' | head -n 1)
            fi

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' --path '/backups/{$(basename $(psql -p $(pgport $ins) -Ant -c 'show data_directory')),module,${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}' --pattern '(postgres|$db)_[0-9-_]+.dump' --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres -d '$db' --dbinclude '$db'  --dbinclude 'postgres' --status-file /tmp/sup_pg_dump_$db.status"
            echo -ne "command[check_pgdump_${ins}_${db}]:\t"
            /usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' --path "/backups/{$(basename $(psql -p $(pgport $ins) -Ant -c 'show data_directory')),module,${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}" --pattern "(postgres|$db)_[0-9-_]+.dump" --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres -d "$db" --dbinclude "$db"  --dbinclude 'postgres' --status-file /tmp/sup_pg_dump_$db.status
            tmpRC=$?
    if [ -n "$DEBUG" ]; then
    echo -n "/usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -F human "
    echo -n "-c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' "
    echo -n "--path \"/backups/{$(basename $(psql -p $(pgport $ins) -Ant -c 'show data_directory')),module,${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}\" "
    echo -n "--pattern \"(postgres|$db)_[0-9-_]+.dump\" "
    echo -n "--global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres "
    echo -n "-d \"$db\" --dbinclude \"$db\" --dbexclude 'postgres' --status-file /tmp/postgres_pg_dump_${db}.status"
    fi
    echo ""
    /usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -F human \
    -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' \
    --path "/backups/${ins}*/*{dump,sql}" \
    --pattern '(\w+)_[0-9-_]+.dump' \
    --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres \
    -d "$db" --dbinclude "$db" --status-file /tmp/postgres_pg_dump_${db}.status > $tmpFile

    lRC=$?

    grep -vE '(postgres|globals)_' $tmpFile| \
    while IFS= read -r line
            do
                echo -n "$line"
                echo $line | grep -q POSTGRES_PGDUMP_BACKUP
                [ $? -eq 0 ] && echo -n " FOR $ins($db)"
                echo $line | grep -q Returns
                [ $? -eq 0 ] && echo -n " FOR DUMP BACKUPS $ins($db)"
                echo
            done
    find /backups/${ins}* -type f -iname "${db}_2*.dump" | xargs -n1 dirname | sort | uniq | perl -pe 's/\n/, /gm' | perl -pe 's/,\s*$//g' | xargs -n 100 echo "BackupDirs     :"
    if [ $maxFile -ne 0 ]; then 
        find /backups/${ins}* -type f -iname "${db}_2*.dump"| sort -n | tac | head -n $maxFile | \
        while IFS= read -r line
        do

            echo -en "LastBackupFile : $(basename $line)\t$(stat -c %y $line|cut -d. -f1)("
            echo -en "$(humanFileAge $line)) $(numfmt --from=iec --to=iec $(stat -c%s $line)) "
            echo -e "$(stat -c%U $line)/$(stat -c%G $line)($(stat -c%a $line))"
        done
        find /backups/${ins}* -type f -iname "${db}_2*.dump"| sort -n | head -n $maxFile | tac | \
        while IFS= read -r line
        do
            echo -en "OldBackupFile  : $(basename $line)\t$(stat -c %y $line|cut -d. -f1)("
            echo -en "$(humanFileAge $line)) $(numfmt --from=iec --to=iec $(stat -c%s $line)) "
            echo -e "$(stat -c%U $line)/$(stat -c%G $line)($(stat -c%a $line))"
        done
    fi
    rm -f $tmpFile
    return $lRC
}

pgcheckallbackups()
{
    local silent=${1:-"nosilent"}
    local maxFile=${2:-"2"}
    local lRC=0
    local tmpRC=0
    for ins in $(pginstances); do 
       [ "$silent" = "nosilent" ] && echo "--------------------------------------------------------"
       for db in $(pgdbs $ins| grep -v postgres); do
            if [ "$silent" = "nosilent" ]; then
                pgcheckbackup $ins $db $maxFile
            else
                pgcheckbackup $ins $db 0 &>/dev/null
            fi
            tmpRC=$?
            [ $tmpRC -gt 0 ] && error "Probleme detecte sur les backups pour l'instance '$ins' et la base '$db'"
            [ $tmpRC -eq 0 ] && info "[OK] Backups pour l'instance '$ins' et la base '$db' [OK]"
                
            lRC=$(($lRC + $tmpRC))
            [ "$silent" = "nosilent" ] && echo "--------------------------------------------------------"
        done
    done
    [ $lRC -gt 0 ] && error "Probleme detecte sur les backups"
    [ $lRC -eq 0 ] && info "[OK] All backups are OK [OK]"
    return $lRC
}

pgsupchecks()
{
    local supReplicationMaster=${1:-0}
    local lRC=0
    local tmpRC=0
    local failMsg="Failed tests:"
    export PGHOST=/tmp
    for ins in $(pginstances); do
        echo -ne "command[check_tcp_${ins}]:\t"
        /usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p $(pgport $ins) -w 1 -c 5
        tmpRC=$?
        lRC=$(($lRC + $tmpRC))
        [ $tmpRC -ne 0 ] && failMsg="$failMsg check_tcp_${ins},"
        echo -e "command[check_tcp_${ins}]-----($tmpRC)"

        [ "$RH_MAJOR_VERSION" != "7" ] && continue
        if [ $supReplicationMaster -ne 2 ]; then
            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s archiver -U postgres -p $(pgport $ins)  -w 15 -c 25 --status-file /tmp/sup_archiver_${db}.status"
            echo -ne "command[check_archiver_${ins}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s archiver -U postgres -p $(pgport $ins)  -w 15 -c 25 --status-file /tmp/sup_archiver_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_archiver_${ins},"
            echo -e "\ncommand[check_archiver_${ins}]-----($tmpRC)"
        fi
        for db in $(pgdbs $ins| grep -vE '(postgres|to_del|_old|2019|2020|2021)'); do
            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s autovacuum -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_autovacuum_${db}.status"
            echo -ne "command[check_autovaccum_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s autovacuum -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_autovacuum_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_autovaccum_${ins}_${db},"
            echo -e "\ncommand[check_autovaccum_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends -U postgres -p $(pgport $ins) -d $db -w 75% -c 90% --status-file /tmp/sup_backends_${db}.status"
            echo -ne "command[check_backends_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends -U postgres -p $(pgport $ins) -d $db -w 75% -c 90% --status-file /tmp/sup_backends_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_backends_${ins}_${db},"
            echo -e "\ncommand[check_backends_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends_status -U postgres -p $(pgport $ins) -d $db -w waiting=5,idle_xact=10 -c waiting=20,idle_xact=30 --status-file /tmp/sup_backends_status_${db}.status"
            echo -ne "command[check_backends_status_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends_status -U postgres -p $(pgport $ins) -d $db -w waiting=5,idle_xact=10 -c waiting=20,idle_xact=30 --status-file /tmp/sup_backends_status_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_backends_status_${ins}_${db},"
            echo -e "\ncommand[check_backends_status_${ins}_${db}]-----($tmpRC)"
            
            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s bgwriter -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_bgwriter_${db}.status"
            echo -ne "command[check_bgwriter_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s bgwriter -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_bgwriter_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_bgwriter_${ins}_${db},"
            echo -e "\ncommand[check_bgwriter_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s connection -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_connection_${db}.status"
            echo -ne "command[check_connection_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s connection -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_connection_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_connection_${ins}_${db},"
            echo -e "\ncommand[check_connection_${ins}_${db}]-----($tmpRC)"
            
            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s database_size -U postgres -p $(pgport $ins) -d $db -w 2G -c 5G --status-file /tmp/sup_dbsize_${db}.status"
            echo -ne "command[check_dbsize_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s database_size -U postgres -p $(pgport $ins) -d $db -w 2G -c 5G --status-file /tmp/sup_dbsize_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_dbsize_${ins}_${db},"
            echo -e "\ncommand[check_dbsize_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s hit_ratio  -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_hitratio_${db}.status"
            echo -ne "command[check_hit_ratio_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s hit_ratio  -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_hitratio_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_hit_ratio_${ins}_${db},"
            echo -e "\ncommand[check_hit_ratio_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s invalid_indexes -U postgres -p $(pgport $ins) -d $db -w 1 -c 5 --status-file /tmp/sup_invalid_indexes_${db}.status"
            echo -ne "command[check_invalid_indexes_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s invalid_indexes -U postgres -p $(pgport $ins) -d $db -w 1 -c 5 --status-file /tmp/sup_invalid_indexes_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_invalid_indexes_${ins}_${db},"
            echo -e "\ncommand[check_invalid_indexes_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_analyze -U postgres -p $(pgport $ins) -d $db --dbexclude '.*(to_del|_old|2019|2020|2021).*' -w 31d -c 90d --status-file /tmp/sup_last_analyze_${db}.status"
            echo -ne "command[check_last_analyze_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_analyze -U postgres -p $(pgport $ins) -d $db --dbexclude '.*(to_del|_old|2019|2020|2021).*' -w 31d -c 90d --status-file /tmp/sup_last_analyze_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_last_analyze_${ins}_${db},"
            echo -e "\ncommand[check_last_analyze_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_vacuum -U postgres -p $(pgport $ins) -d $db -w 31d -c 90d --status-file /tmp/sup_last_vacuum_${db}.status"
            echo -ne "command[check_last_vacuum_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_vacuum -U postgres -p $(pgport $ins) -d $db -w 31d -c 90d --status-file /tmp/sup_last_vacuum_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_last_vacuum_${ins}_${db},"
            echo -e "\ncommand[check_last_vacuum_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s locks -U postgres -p $(pgport $ins) -d $db -w 5% -c 10% --status-file /tmp/sup_locks_${db}.status"
            echo -ne "command[check_locks_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s locks -U postgres -p $(pgport $ins) -d $db -w 5% -c 10% --status-file /tmp/sup_locks_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_locks_${ins}_${db},"
            echo -e "\ncommand[check_locks_${ins}_${db}]-----($tmpRC)"
            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s longest_query -U postgres -p $(pgport $ins) --dbexclude 'template1' -d $db -w 60s -c 1500s --status-file /tmp/sup_long_query_${db}.status"
            echo -ne "command[check_long_query_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s longest_query -U postgres -p $(pgport $ins) -d $db --dbexclude 'template1' -w 60s -c 1500s --status-file /tmp/sup_long_query_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_long_query_${ins}_${db},"
            echo -e "\ncommand[check_long_query_${ins}_${db}]-----($tmpRC)"
            

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s oldest_idlexact -U postgres -p $(pgport $ins) -d $db -w 1260 -c 2100 --status-file /tmp/sup_oldest_idlexact_${db}.status"
            echo -ne "command[check_oldest_idlexact_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s oldest_idlexact -U postgres -p $(pgport $ins) -d $db -w 1260 -c 2100 --status-file /tmp/sup_oldest_idlexact_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_oldest_idlexact_${ins}_${db},"
            echo -e "\ncommand[check_oldest_idlexact_${ins}_${db}]-----($tmpRC)"

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s sequences_exhausted -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_exhausted_seq_${db}.status"
            echo -ne "command[check_sequences_exhausted_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s sequences_exhausted -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/sup_exhausted_seq_${db}.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_sequences_exhausted_${ins}_${db},"
            echo -e "\ncommand[check_sequences_exhausted_${ins}_${db}]-----($tmpRC)"

            dbname=$ins
            echo $ins | grep -q generic
            if [ $? -eq 0 ]; then
                dbname=$(pgdbs $ins| grep -vE  '(postgres|to_del|_old|2019|2020|2021|alfresco)' | head -n 1)
            fi

            [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' --path '/backups/{$(basename $(psql -U postgres -p $(pgport $ins) -Ant -c 'show data_directory')),module,${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}' --pattern '(postgres|$db)_[0-9-_]+.dump' --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres -d '$db' --dbinclude '$db'  --dbinclude 'postgres' --status-file /tmp/sup_pg_dump_$db.status"
            echo -ne "command[check_pgdump_${ins}_${db}]:\t"
            timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s pg_dump_backup -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' --path "/backups/{$(basename $(psql -U postgres -p $(pgport $ins) -Ant -c 'show data_directory')),module,${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}" --pattern "(postgres|$db)_[0-9-_]+.dump" --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -U postgres -d "$db" --dbinclude "$db"  --dbinclude 'postgres' --status-file /tmp/sup_pg_dump_$db.status
            tmpRC=$?
            lRC=$(($lRC + $tmpRC))
            [ $tmpRC -ne 0 ] && failMsg="$failMsg check_pgdump_${ins}_${db},"
            echo -e "\ncommand[check_pgdump_${ins}_${db}]-----($tmpRC)"
            if [ $supReplicationMaster -eq 1 ]; then
                [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s streaming_delta -U postgres -p $(pgport $ins) -d $db -w 100Mo -c 300Mo --status-file /tmp/sup_streaming_delta_${db}.status"
                echo -ne "command[check_streaming_delta_${ins}_${db}]:\t"
                timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s streaming_delta -U postgres -p $(pgport $ins) -d $db -w 100Mo -c 300Mo --status-file /tmp/sup_streaming_delta_${db}.status
                tmpRC=$?
                lRC=$(($lRC + $tmpRC))
                [ $tmpRC -ne 0 ] && failMsg="$failMsg check_streaming_delta_${ins}_${db},"
                echo -e "\ncommand[check_streaming_delta_${ins}_${db}]-----($tmpRC)"
                [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s replication_slots -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_replication_slots_${db}.status"
                echo -ne "command[check_replication_slots_${ins}_${db}]:\t"
                timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s replication_slots -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_replication_slots_${db}.status
                tmpRC=$?
                lRC=$(($lRC + $tmpRC))
                [ $tmpRC -ne 0 ] && failMsg="$failMsg check_replication_slots_${ins}_${db},"
                echo -e "\ncommand[check_replication_slots_${ins}_${db}]-----($tmpRC)"
                [ "$DEBUG" = "1" ] && echo "/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s is_master -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_is_master_${db}.status"
                echo -ne "command[check_is_master_${ins}_${db}]:\t"
                timeout 10s /usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s is_master -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/sup_is_master_${db}.status
                tmpRC=$?
                lRC=$(($lRC + $tmpRC))
                [ $tmpRC -ne 0 ] && failMsg="$failMsg check_is_master_${ins}_${db},"
                echo -e "\ncommand[check_is_master_${ins}_${db}]-----($tmpRC)"
            fi
        done
    echo '#################################################################################################################'
    done
    if [ $lRC -eq 0 ]; then
        echo "ALL IS OK :)"
    else
        echo "Some errors: "
        echo $failMsg
    fi
    is user root
    [ $? -eq 0 ] && chown postgres. /tmp/sup*.status /tmp/postgres*.status
    return $lRC
}

pglistnrpecmds()
{
    grep -E 'command\[check_' /etc/nagios/nrpe.cfg | cut -d[ -f2| cut -d] -f1 | sed 's/check_//g'
}
pggennrpechecks()
{
    local supReplicationMaster=${1:-0}
    echo "command[check_psql_checks]=/admin/scripts/nrpe/check_psql_checks.sh"
    for ins in $(pginstances); do
        echo ""
        echo "## Checks PostgreSQL(check_psql) : ${ins}/${db} $(hostname -s):$(pgport $ins)"
        echo "command[check_psql_tcp_${ins}]=/usr/lib64/nagios/plugins/check_tcp -H 127.0.0.1 -p $(pgport $ins) -w 1 -c 5"
        [ "$RH_MAJOR_VERSION" != "7" ] && continue
        #[ $supReplicationMaster -ne 2 ] && echo "command[check_psql_archiver_${ins}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s archiver -U postgres -p $(pgport $ins) -w 15 -c 25 --status-file /tmp/nrpe_psql_archiver_${ins}.status"
        #[ $supReplicationMaster -ne 3 ] && echo "command[check_psql_archiver_${ins}]=/usr/lib64/nagios/plugins/check_pgactivity -s custom_query --query \"select count(*) from pg_settings where name='archive_mode' and setting = 'on'\" -U postgres -p $(pgport $ins) -h/tmp -w 0 -c 0 --status-file /tmp/nrpe_psql_archiver_${ins}.status"
        echo "command[check_psql_hit_ratio_${ins}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s hit_ratio  -U postgres -p $(pgport $ins) -d postgres --dbexclude 'postgres' -w 80% -c 90% --status-file /tmp/nrpe_psql_hitratio_${ins}.status"
        echo "command[check_psql_long_query_${ins}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s longest_query -U postgres -p $(pgport $ins) -d $db -w 60s -c 1500s --status-file /tmp/nrpe_psql_long_query_${ins}.status"
          
        for db in $(pgdbs $ins | grep -vE  '(postgres|_old|to_del|2019|2020|2021|rescue)'); do
            echo "command[check_psql_autovaccum_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s autovacuum -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/nrpe_psql_autovacuum_${db}.status"
            echo "command[check_psql_backends_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends -U postgres -p $(pgport $ins) -d $db -w 75% -c 90% --status-file /tmp/nrpe_psql_backends_${db}.status"
            echo "command[check_psql_backends_status_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s backends_status -U postgres -p $(pgport $ins) -d $db -w waiting=5,idle_xact=10 -c waiting=20,idle_xact=30 --status-file /tmp/nrpe_psql_backends_status_${db}.status"
            echo "command[check_psql_bgwriter_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s bgwriter -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/nrpe_psql_bgwriter_${db}.status"
            echo "command[check_psql_connection_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s connection -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/nrpe_psql_connection_${db}.status"
            echo "command[check_psql_dbsize_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s database_size -U postgres -p $(pgport $ins) -d $db -w 2G -c 5G --status-file /tmp/nrpe_psql_dbsize_${db}.status"
            echo "command[check_psql_invalid_indexes_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s invalid_indexes -U postgres -p $(pgport $ins) -d $db -w 1 -c 5 --status-file /tmp/nrpe_psql_invalid_indexes_${db}.status"
            echo "command[check_psql_last_analyze_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_analyze -U postgres -p $(pgport $ins) -d $db -w 31d -c 90d --status-file /tmp/nrpe_psql_last_analyze_${db}.status"
            echo "command[check_psql_last_vacuum_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s last_vacuum -U postgres -p $(pgport $ins) -d $db -w 31d -c 90d --status-file /tmp/nrpe_psql_last_vacuum_${db}.status"
            echo "command[check_psql_locks_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s locks -U postgres -p $(pgport $ins) -d $db -w 5% -c 10% --status-file /tmp/nrpe_psql_locks_${db}.status"
            echo "command[check_psql_oldest_idlexact_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s oldest_idlexact -U postgres -p $(pgport $ins) -d $db -w 1260 -c 2100 --status-file /tmp/nrpe_psql_oldest_idlexact_${db}.status"
            echo "command[check_psql_sequences_exhausted_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s sequences_exhausted -U postgres -p $(pgport $ins) -d $db -w 80% -c 90% --status-file /tmp/nrpe_psql_exhausted_seq_${db}.status"
            
            dbname=$ins
            echo $ins | grep -q generic
            if [ $? -eq 0 ]; then
                dbname=$(pgdbs $ins| grep -vE  '(postgres|to_del|_old|2019|2020|2021)' | head -n 1)
            fi
            echo "command[check_psql_pgdump_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -s pg_dump_backup -c 'oldest=60d,newest=50h,size=100M' -w 'oldest=40d,newest=26h,size=60M' --path '/backups/{$(basename $(psql -U postgres -p $(pgport $ins) -Ant -c 'show data_directory')),${dbname},$ins,instance.$(pgport $ins)}*/*{dump,sql}' --pattern '(postgres|$db)_[0-9-_]+.dump' --global-pattern='pg_global_[0-9-_]+.sql' -p $(pgport ${ins}) -h /tmp/ -U postgres  -d '$db' --dbinclude '$db'  --dbinclude 'postgres' --status-file /tmp/nrpe_psql_pg_dump_$db.status"
             if [ $supReplicationMaster -eq 1 ]; then
                echo "command[check_psql_streaming_delta_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s streaming_delta -U postgres -p $(pgport $ins) -d $db -w 100Mo -c 300Mo  --status-file /tmp/nrpe_psql_streaming_deleta_$db.status"
                echo "command[check_psql_replication_slots_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s replication_slots -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/nrpe_psql_replication_slots_$db.status"
                echo "command[check_psql_is_master_${ins}_${db}]=/usr/lib64/nagios/plugins/check_pgactivity -h /tmp -s is_master -U postgres -p $(pgport $ins) -d $db -w 0 -c 0 --status-file /tmp/nrpe_psql_is_master_$db.status"
            fi
        done
    done
}


pgupdatenrpeconf()
{
    supReplicationMaster=$1
    [ "$RH_MAJOR_VERSION" = "7" ] || return 1
    [ -d "/base" ] || return 2
    [ -d "/backups" ] || return 3
    [ -d "/var/lib/pgsql" ] || return 4
    local supReplicationMaster=${1:-0}
    local hordate=$(date "+%Y-%m-%d_%H-%M-%S")
    cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg.${hordate}
    sed -i '/check_psql/d' /etc/nagios/nrpe.cfg
    #sed -i '/check_psql/d' /etc/nagios/nrpe.cfg
    perl -i.bak -pe 's/^(allowed_hosts)=.*/$1=127.0.0.1,192.168.68.0/2/g;s/^(dont_blame_nrpe|allow_bash_command_substitution|debug)=.*/$1=1/g' /etc/nagios/nrpe.cfg

    echo "" >> /etc/nagios/nrpe.cfg
    pggennrpechecks $supReplicationMaster >> /etc/nagios/nrpe.cfg
    sed -i 'N;/^\n$/D;P;D;' /etc/nagios/nrpe.cfg
    chown root.root /etc/nagios/nrpe.cfg
    #chown nrpe.nrpe /tmp/nrpe_*.status
    usermod -aG postgres nrpe
    usermod -aG root nrpe
    systemctl restart nrpe
    cat /etc/nagios/nrpe.cfg
    [ -d "/var/lib/pgsql" ] && chmod g+r-w /var/lib/pgsql
    [ -d "/admin/scripts/nrpe" ] && chmod -R 755 /admin/scripts/nrpe
    grep status-file /etc/nagios/nrpe.cfg| perl -pe 's/.*status-file //g' | grep nrpe | \
    while IFS= read -r line; do
        [ -f "$line" ] && rm -f $line
    done
    true
}

pgcheckallnrpeconf()
{
    local lFilter=${1:-'.*'}
    lRC=0
    tmpRc=0
    grep 'command\[check_psql' /etc/nagios/nrpe.cfg | cut -d\] -f1| cut -d\[ -f2 | grep -E "$lFilter" | while IFS= read -r line; do
        echo "---------------------------------------------------------"
        echo "$line"
        echo "---------------------------------------------------------"
        /usr/lib64/nagios/plugins/check_nrpe -4 -H 127.0.0.1 -c $line 
        tmpRc=$?
        if [ $tmpRc -ne 0 ]; then
            error "CHECKING $line => FAILED"
        else
            info "CHECKING $line => OK"
        fi
        lRC=$((lRC + $tmpRc))
        echo ""
        echo ""
        
    done
}

#nagios-plugins-nrpe.x86_64

pgcounttables()
{
	local ins=${1:-""}
	local db=${2:-"$ins"}
	local schema=${3:-"$ins"}
 	psql -p $(pgport ${ins}) $db -tA -c "select count(tablename) from pg_tables where schemaname='${schema}'"
 }
 
pgcountlines()
{
	local ins=${1:-""}
    local db=${2:-"$ins"}
    local schema=${3:-"$ins"}
    local excl_patterns=${4:-"error"}
 	for tbl in $(psql -p $(pgport ${ins}) $db -tA -c "select tablename from pg_tables where schemaname='${schema}' order by tablename"); do 
 		echo "${schema}.${tbl}" | grep -qE "$excl_patterns" 
 		if [ $? -ne 0 ];then
 			echo -ne "$tbl\t"
 			psql -p $(pgport ${ins}) $db -tA -c "select count(*) from ${schema}.$tbl"
 		fi
   done
}

pgemptytables()
{
    pgcountlines $* |sort -n -k2 | grep -E "\s0$" | column -t
}

pgscountlines()
{
	pgcountlines $* | sort -nr -k2 | column -t
}

pgacountlines()
{
    pgcountlines $* | column -t
}


pgfindlastbackups()
{
    local nbb=${1:-"20"}
    local ins=${2:-""}
    if [ -n "$ins" ]; then
        find /backups/ -type f -iname '*.dump' -printf "%T+\t%p\n" | grep -v 'postgres_' | sort -rn | grep -v 'export' | grep "${ins}_20" | head -n $nbb
        return 0
    fi
    find /backups/ -type f -iname '*.dump' -printf "%T+\t%p\n" | grep -v 'export' | grep -v 'postgres_' | sort -rn | head -n $nbb
}

pglrestorelast()
{
    local ins=${1:-""} 
    local db=${2:-"$ins"}
    [ -z "$ins" ] && return 127
    title2 "10 Last Backups pour l'instance $ins :"
    pgfindlastbackups 10 $ins
    title2 "Last Backup pour l'instance $ins :"
    pgfindlastbackups 1 $ins
    confirm "Restaure l'instance $ins avec le backups $(pgfindlastbackups 1 $ins| awk '{print $2}')"
    [ $? -eq 0 ] && pglrestore $ins $db $(pgfindlastbackups 1 $ins| awk '{print $2}') go
}

pglrestore()
{
	local ins=${1:-""}
	local db=${2:-"$ins"}
	local target_backup=${3:-""}
    local DOIT=${4:-""}
	local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
	local logfile="$(dirname $target_backup)/pg_restore_${ins}_${db}_${horodate}.log"
	local RC=255
	if [ -z "$ins" ]; then
		echo "NO INSTANCE"
		return 255
	fi
	if [ -z "$db" ]; then
		echo "NO DB"
		return 255
	fi
	if [ ! -f "$target_backup" ]; then
		echo "$target_backup not a regular file"
		return 255
	fi
    pgdbs $ins | grep -qE "^$db$"
    if [ $? -eq 0 ]; then
        info "Rennomage de la base $db existante de l'instance $ins"
        pgswitchnewdb $ins $db $DOIT
	fi
    info "Restauration base $db pour l'instance PostgreSQL ${ins}"
	echo "pg_restore -p $(pgport ${ins}) -v -c --if-exists -d $db $target_backup 2>&1 | tee -a $logfile"
	[ "$DOIT" == "go" ] && pg_restore -p $(pgport ${ins}) -v -c --if-exists -d $db $target_backup 2>&1 | tee -a $logfile
	RC=$?
	touch $logfile
	info "Fin de la restauration base $db pour l'instance PostgreSQL ${ins}"
	info "STATUS RESTAURATION: $RC"
	
	info "Analyse du fichier de log: $logfile"
    nb_errors=$(grep -cE '(error|warn)' $logfile)
	grep -E '(error|warn)' $logfile
	info "Fin d'analyse du fichier de log: $logfile"
	info "NB ERREUR DANS LES LOG: $nb_errors"
	RC=$(($RC + $nb_errors))
	
    cmd "Remise en place des droits" "pguserprivs $ins $ins | psql -p $(pgport $ins) $db"

    cmd "Analyse des données de stat." "vacuumdb -p $(pgport $ins) -az"
    #set +x
	return $RC
}

pgdumpfdw()
{
	local ins=${1:-""}
	local db=${2:-"$ins"}
	local alter_mode=${3}
	if [ "$alter_mode" = "1" ]; then
		pg_dump -p $(pgport ${ins}) -U postgres --no-acl -s $db | grep -B4 -A4 -E '(ALTER|CREATE) (USER MAPPING|SERVER)' | perl -pe 's/CREATE (SERVER|USER MAPPING)/ALTER $1/' || sed 's/FOREIGN DATA WRAPPER postgres_fdw//g'| perl -pe 's/.*?(\"*user|password|dbname|host|port|updatable)/SET $1/g'
	else
		pg_dump -p $(pgport ${ins}) -U postgres --no-acl -s $db | grep -B4 -A4 -E '(ALTER|CREATE) (USER MAPPING|SERVER)' 
	fi
}

pgflushdb()
{
	local ins=${1:-""}
	local db=${2:-"$ins"}
	pg_dump -p $(pgport ${ins}) -U postgres --no-acl -C --clean -s $db | perl -ne '/(ALTER|CREATE) DATABASE/ and print'
}

pgsecuredir()
{
	for d in /admin /base /backups /wal /archives /data; do
		if [ -d "$d" ]; then
			if [ "$1" = "1" ]; then
				chown postgres.postgres $d
				chmod o-rwx $d
			fi
			echo -e "$d\t$(stat -c%U $d)\t$(stat -c%G $d)\t$(stat -c%A $d)"
		fi
	done | column -t
}

pgscript()
{
	#set -x
	local ins=${1:-""}
	local db=${2:-"$ins"}
	local script_file=${3:-""}
    local dry_run=${4:-"dry_run"}
	local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
	local logfile="${script_file/.sql/_$(hostname -s)_${ins}_${db}.${horodate}}"
    [ "$dry_run" = "dry_run" ] && logfile=${logfile}.ROLLBACK.log
    [ "$dry_run" = "dry_run" ] || logfile=${logfile}.COMMIT.log
	touch $logfile
	local RC=255
	if [ -z "$ins" ]; then
		echo "NO INSTANCE"
		return 255
	fi
	if [ -z "$db" ]; then
		echo "NO DB"
		return 255
	fi
	if [ ! -f "$script_file" ]; then
		echo "$script_file not a regular file" 
		return 255
	fi

    title1 "REALISER TOUJOURS UNE SAUVEGARDE AVEC LA COMMANDE SUIVANTE POUR CE TYPE D OPERATION" | tee -a $logfile
    title2 "$(pggetcrontabpgback $ins)" | tee -a $logfile

	info "Execution de $(basename $script_file) base $db pour l'instance PostgreSQL ${ins}" | tee -a $logfile
    grep -iq "commit" $script_file
    if [ $? -eq 0 ]; then
        error "$script_file CONTAINS commit keyword" | tee -a $logfile
        grep -Hni "commit" $script_file | tee -a $logfile
        return 12
    fi
    if [ "$dry_run" = "dry_run" ]; then
       info "DRY RUN $script_file on ${ins} => $db" | tee -a $logfile
       echo "cat $script_file | psql -p $(pgport ${ins}) -v ON_ERROR_STOP=1 -a -E  $db 2>&1" | tee -a $logfile
       ( echo -e "\set autocommit off;\nset search_path = public, '$db';\nBEGIN;"; cat $script_file | dos2unix |grep -vE '^--'; echo "ROLLBACK;") | psql -p $(pgport ${ins}) -v ON_ERROR_STOP=1 -a -E  $db >${logfile}_tmp 2>&1
    else
        info "Running for REAL $script_file on ${ins} => $db" | tee -a $logfile
        echo "cat $script_file | psql -p $(pgport ${ins}) -v ON_ERROR_STOP=1 -a -E  $db 2>&1" | tee -a $logfile
        ( echo -e "\set autocommit off;\nset search_path = public, '$db';\nBEGIN;";cat $script_file| dos2unix |grep -vE '^--'; echo "COMMIT;") | psql -p $(pgport ${ins}) -v ON_ERROR_STOP=1 -a -E  $db >${logfile}_tmp 2>&1
    fi
	RC=$?
    cat ${logfile}_tmp | tee -a ${logfile}
    rm -f ${logfile}_tmp
    info "Read logfile for more details: $logfile"
	info "Fin d'execution de $(basename $script_file) base $db pour l'instance PostgreSQL ${ins}" | tee -a $logfile
	info "STATUS RESTAURATION: $RC" | tee -a $logfile
	info "Analyse du fichier de log: $logfile" | tee -a $logfile
	nb_errors=$(grep -ciE '(err |error:|error |warn |warning |fatal )' $logfile)
	grep -Ei '(err |error:|error |warn |warning |fatal )' $logfile | tee -a $logfile
	info "Fin d'analyse du fichier de log: $logfile" | tee -a $logfile
	info "NB ERREUR DANS LES LOG: $nb_errors" | tee -a $logfile
	RC=$(($RC + $nb_errors)) 
	info "FINAL RC: $RC"  | tee -a $logfile
    [ $RC -gt 0 ] && mv $logfile ${logfile/.log/.err}
	return $RC
}

pgexportcsv()
{
    #set -x
    local ins=${1:-""}
    local db=${2:-"$ins"}
    local script_file=${3:-""}
    [ -z "$3" ] && exit 127
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local logfile="${script_file/.sql/_$(hostname -s)_${ins}_${db}.${horodate}}"
    [ -f "$script_file" ] || logfile="${script_file}_$(hostname -s)_${ins}_${db}.${horodate}"
    sqlResultFile=$(readlink -f "${logfile}.csv")
    logfile=${logfile}.EXPORT.log
    
    touch $logfile
    local RC=255
    if [ -z "$ins" ]; then
        echo "NO INSTANCE"
        return 255
    fi
    if [ -z "$db" ]; then
        echo "NO DB"
        return 255
    fi
    info "Construction de la chaine de COPY pour la base $db pour l'instance PostgreSQL ${ins}" | tee -a $logfile
    
    tmpFile=$(mktemp)
    echo "set search_path = public, '$db';" > $tmpFile
    echo "COPY " >> $tmpFile
    if [ -f "$script_file" ];then
        echo "( " >> $tmpFile
        sed 's/;//g' $script_file >> $tmpFile
        echo ") " >> $tmpFile
    else
        echo $script_file >> $tmpFile
    fi
    echo "TO '$sqlResultFile' DELIMITER ';' HEADER CSV;" >> $tmpFile
    info "Requete SQL de copie :"
    cat $tmpFile
    info "Running for REAL $script_file on ${ins} => $db" | tee -a $logfile
    cat $tmpFile | psql -p $(pgport ${ins}) -v ON_ERROR_STOP=1 -a -E  $db >${logfile}_tmp 2>&1
    RC=$?
    cat ${logfile}_tmp | tee -a ${logfile}
    rm -f ${logfile}_tmp $tmpFile
    info "Read logfile for more details: $logfile"
    info "Fin d'execution de $(basename $script_file) base $db pour l'instance PostgreSQL ${ins}" | tee -a $logfile
    info "STATUS RESTAURATION: $RC" | tee -a $logfile
    info "Analyse du fichier de log: $logfile" | tee -a $logfile
    nb_errors=$(grep -ciE '(err |error:|error |warn |warning |fatal )' $logfile)
    grep -Ei '(err |error:|error |warn |warning |fatal )' $logfile | tee -a $logfile
    info "Fin d'analyse du fichier de log: $logfile" | tee -a $logfile
    info "NB ERREUR DANS LES LOG: $nb_errors" | tee -a $logfile
    info "Result CSV file: $sqlResultFile ($(wc -l $sqlResultFile| awk '{print $1}') lines)"
    RC=$(($RC + $nb_errors)) 
    info "FINAL RC: $RC"  | tee -a $logfile
    [ $RC -gt 0 ] && mv $logfile ${logfile/.log/.err}
    return $RC
}

lastestpgglobals()
{
    local d=${1:-"."}
    find $d -type f -printf '%T@ %p\n' | grep 'pg_global' |sort -nr | head -n 1 | cut -f2- -d" "|xargs -n1 ls -1
}

randpw() {
	if [ ! -f "/usr/bin/pwgen" ]; then
		echo "yum -y install pwgen"
		return 1
	fi
	pwgen -c -n -y -v 12 1
	return $?
}

mksha256file()
{
    f=$1
    [ -z "$f" -o ! -f "$1" ] && return 1

    sha256sum $1  | awk '{print $1}' > $1.sha256sum
}

check_sha256file()
{
    if [ ! -f "$1" ]; then
        error "$1 DOESNT EXIST"
        return 1
    fi
    if [ ! -f "$1.sha256sum" ]; then
        error "$1.sha256sum DOESNT EXIST"
        return 1
    fi
    
    SIGN_FILE=$(sha256sum $1  | awk '{print $1}')
    SIGN_CONTENT=$(cat $1.sha256sum)

    if [ "$SIGN_FILE" = "$SIGN_CONTENT" ]; then
        info "$(basename $1) SIGNATURE IS OK"
        return 0
    fi
    info "$(basename $1) SIGNATURE IS WRONG ( $SIGN_FILE vs $SIGN_CONTENT )"
    return 1
}
lastestfile()
{
	local d=${1:-"."}
	local nb=${2:-"10"}
	find $d -type f -printf '%T@ %p\n' | sort -nr | head -n ${nb} | cut -f2- -d" "|xargs -n1 ls -lsh
}

slastestfile()
{
    local d=${1:-"."}
    local nb=${2:-"10"}
    find $d -type f -printf '%T@ %p\n' | sort -nr | head -n ${nb} | cut -f2- -d" "| awk '{ print $NF}' |xargs -n1
}

oldestFilesToRemoveNFiles()
{
    ls -tp $1 | grep -v '/$' | tail -n +$(($2 + 1)) | xargs -n 1 -I{} echo "$1/{}"
}

keepNFilesintoDir()
{
    oldestFilesToRemoveNFiles $*  | xargs -n 1  rm -f 
}


cmd()
{
    local lRC=$?
 
    if [ $lRC -ne 0 ]; then
        scrstop $lRC
    fi
    local label="$1"
    shift
    local comm=$1
    shift
    local output=$1
    shift

    title2 "$label"
    info "command started : $comm"
    if [ -n "$output" ]; then
        $comm > $output
    else
        eval $comm 2>&1
    fi
    lRC=$?
    info "command ended : $comm"
    [ -n "$output" ] && info "output file: $output"
    title2 "$label - Status: $lRC"
    return $lRC
}


sshcmd()
{
    local lRC=$?
    if [ $lRC -ne 0 ]; then
        scrstop $lRC
    fi
    local target=$1
    shift
    local label="$1"
    shift
    local comm=$1
    shift
    local output=$1
    shift

    title2 "@$target => $label"
    info "@$target => command started : $comm"
    if [ -n "$output" ]; then
        ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target "$comm" > $output
    else
        ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target "$comm" 2>&1 
    fi
    lRC=$?
    info "@$target => command ended : $comm"
    [ -n "$output" ] && info "@$target => output file: $output"
    title2 "@$target => $label - Status: $lRC"
    return $lRC
}

pgsshcmd()
{
    local lRC=$?
    if [ $lRC -ne 0 ]; then
        scrstop $lRC
    fi
    local target=$1
    shift
    local label="$1"
    shift
    local comm=$1
    shift
    local output=$1
    shift

    title2 "@$target => $label"
    info "@$target => command started : $comm"
    if [ -n "$output" ]; then
        ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target "source /var/lib/pgsql/postgres_bash_profile;$comm" > $output
    else
        ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target "source /var/lib/pgsql/postgres_bash_profile;$comm" 2>&1 
    fi
    lRC=$?
    info "@$target => command ended : $comm"
    [ -n "$output" ] && info "@$target => output file: $output"
    title2 "@$target => $label - Status: $lRC"
    return $lRC
}

sshrsync()
{
    local lRC=$?
    if [ $lRC -ne 0 ]; then
        scrstop $lRC
    fi
    local label="$1"
    shift
    
    comm="rsync -e 'ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -ahvz $* --ignore-errors --delete --delete-after"
    title2 "RSYNC: $label - Force Mirroring"
    info "rsync started : rsync -e 'ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -ahvz $* --ignore-errors --delete --delete-after - Force Mirroring"
    rsync -e 'ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -ahvz $* --ignore-errors --delete --delete-after
    lRC=$?
    info "rsync ended : $comm - Force Mirroring"
    title2 "RSYNC: $label - Status: $lRC"
    return $lRC
}

sshcopy()
{
    local lRC=$?
    if [ $lRC -ne 0 ]; then
        scrstop $lRC
    fi
    local label="$1"
    shift
    
    comm="rsync -e 'ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -ahvz $* --ignore-errors"
    local param="$*"
    shift
    info "@$target => rsync started : $comm"
    
    rsync -e 'ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -ahvz $param --ignore-errors
    lRC=$?
    info "@$target => rsync ended : $comm"
    title2 "@$target => RSYNC: $label - Status: $lRC"
    return $lRC
}

scrstart()
{
    export LABEL=${LABEL:-"$1"}
    banner $LABEL
}

scrstop()
{
    lRC=$1
    info "LOG FILE: $LOG_FILE"
    footer $LABEL
    [ $lRC = "0" ] || die $LABEL
}


pginstall_backup_tools()
{

is user root
[ $? -eq 0 ] || return 255
info "Clean des caches YUM"
yum clean all
info "Install pg_back et pigz"
yum -y install pigz pg_back
info "Install. terminee"
}

pgsetup_admin_arbo()
{

is user root
[ $? -eq 0 ] || return 255
info "Creation de l'arborescence standard /admin avec logs, etc et scripts"
mkdir -p /admin/etc /admin/logs /admin/scripts
chown -R postgres.postgres /admin/etc /admin/logs /admin/scripts
chmod -R 750 /admin/etc /admin/logs 
chmod -R 755 /admin/scripts
ls -lsh /admin /admin/*
info "Creation terminee"
}

help_runas()
{
    echo "You can use this script as ${1:-'postgres'} only"
    echo "> su - ${1:-"postgres"}"
    echo "> cd $(dirname $0)"
    echo "> sh $(basename $0) $*"
    echo "Bye"
    exit 127 
}

pgsetup_purge_directory()
{
    is user root
    [ $? -eq 0 ] || return 255

    local folder=$1
    local maxFiles=$2
    local maxMinutes=$3


    info "Mise a jour de la crontab"
    crontab -l -u postgres 2>>/dev/null| { grep -v "purgefile.sh $folder";grep -v "ertoire $folder"; echo; echo "# Purge des fichiers du répertoire $folder toutes les $maxMinutes minutes - - Seuls les $maxFiles fichiers les plus recents sont conserves"; echo "*/$maxMinutes * * * * sh /admin/scripts/purgefile/purgefile.sh $folder $maxFiles &>>/admin/logs/purge_file$(echo $folder| tr '/' '_').log"; } | crontab -u postgres -

    info "Contenu de la crontab Postgres"
    crontab -l -u postgres
}
pgsetup_pg_back_conf()
{

is user root
[ $? -eq 0 ] || return 255
local instance=$1
local port=$2
[ -z "$instance" ] && return 1
[ -z "$port" ] && port=$(pgport $instance)

mkdir -p /admin/etc
chown postgres.postgres /admin/etc
chmod 750 /admin/etc


info "creation du fichier de configuration /admin/etc/pg_back_${instance}.conf"

(
cat << 'END'
# Configuration file for pg_back for {{ TARGET_INSTANCE }}

# Path
export PATH=/usr/pgsql-9.5/bin/:/usr/pgsql-9.6/bin/:/usr/pgsql-10/bin/:/usr/pgsql-11/bin/:/usr/pgsql-12/bin/:/usr/pgsql-13/bin/:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH
cd /tmp
# PostgreSQL binaries path. Leave empty to search $PATH
PGBK_BIN=
export PGPORT={{ PGPORT }}
# Backup directory
PGBK_BACKUP_DIR=/backups/{{ TARGET_INSTANCE }}

# The timestamp to add at the end of each dump file
PGBK_TIMESTAMP='%Y-%m-%d_%H-%M-%S'

# The time limit for old backups, in days
PGBK_PURGE=30

# The minimum number of backups to keep when purging or 'all' to keep
# everything (e.g. disable the purge)
PGBK_PURGE_MIN_KEEP=0

# Command-line options for pg_dump
# (Beware: on v11 and above, with "-Fp", you probably want to add "--create")
PGBK_OPTS="-Fc -p {{ PGPORT }}"

# List of databases to dump (separator is space)
# If empty, dump all databases which are not templates
#PGBK_DBLIST="db1 db2"

# Exclude databases (separator is space)
#PGBK_EXCLUDE="sampledb1 testdb2"

# Include templates ("yes" or "no")
PGBK_WITH_TEMPLATES="no"

# Connection options
#PGBK_HOSTNAME=
#PGBK_PORT=
#PGBK_USERNAME=
#PGBK_CONNDB=postgres
export PGPORT={{ PGPORT }}
END
) > /admin/etc/pg_back_${instance}.conf

info "Ajout des informations dans le fichier de configuration"
perl -i -pe "s/{{ TARGET_INSTANCE }}/$instance/g;s/{{ PGPORT }}/$port/g" /admin/etc/pg_back_${instance}.conf

info "Ajout des droits UNIX sur le fichier de configuration"
chown -R postgres.postgres /admin/etc/pg_back_${instance}*
chmod -R 750 /admin/etc/pg_back_${instance}*

info "Creation du répertoire de backup"
mkdir -p /backups/${instance}
chown -R postgres.postgres /backups/${instance}
chmod -R 750 /backups/${instance}

info "Mise a jour de la crontab"
crontab -l -u postgres 2>>/dev/null| { grep -v "\/admin\/etc\/pg_back_${instance}.conf"; echo "30 03 * * * /bin/bash -c \"/usr/bin/pg_back -c /admin/etc/pg_back_${instance}.conf &>>/admin/logs/pg_back_${instance}.log\""; } | crontab -u postgres -

info "Contenu de la crontab Postgres"
crontab -l -u postgres
}

if is not equal "${BASH_SOURCE[0]}" "$0"; then
    export -f is
else
    is "${@}"
    exit $?
fi

pg_backall()
{
    for ins in $(pginstances); do
        ls -1 /admin/etc/pg_back_${ins}*.conf
    done
}

pggen_psqlrc()
{
is user postgres
[ $? -eq 0 ] || return 255

echo "\set PROMPT1 '%[%033[1;31m%]%`hostname -s`%[%033[0m%]:%[%033[33m%]%> %[%033[1;34m%]%n%[%033[0m%]@%[%033[31m%]%/%[%033[0m%]%R%[%033[0m%]%# '"> $HOME/.psqlrc
echo "\set AUTOCOMMIT on" >> $HOME/.psqlrc
}
pggen_psqlrc

is user postgres
if [ $? -eq 0 ]; then
	export PS1='\[\e[m\]$PROJECT_ENV\[\e[m\]-\[\e[1;35m\][\[\e[m\]\[\e[1;34m\]\u\[\e[m\]\[\e[1m\]@\[\e[m\]\[\e[1;31m\]\h\[\e[m\] \[\e[0;33m\]\[\e[36m\]\w\[\e[m\]\[\e[1;35m\]]\[\e[m\]\[\e[0;33m\]\\$\[\e[m\] '
else
	export PS1='\[\e[m\]$PROJECT_ENV\[\e[m\]-\[\e[1;35m\][\[\e[m\]\[\e[1;34m\]\u\[\e[m\]\[\e[1m\]@\[\e[m\]\[\e[1;31m\]\h\[\e[m\] \[\e[0;33m\]\[\e[36m\]\w\[\e[m\]\[\e[1;35m\]]\[\e[m\]\[\e[0;33m\] #\[\e[m\] '
fi

#===============================
#Creation d'un publisher pour la replication logique à partir d'un fichier d'exclusion de tables 
#SLR 2019.10.15
#https://www.loxodata.com/post/migration_logique/ 
pggenpublication()
{
        local ins=${1:-""}
        local db=${2:-""}
        local schema=${3:-"public"}
        local publication_name=${4:-pub_${ins}}
        local excl_patterns=${5:-"ALL"}

        #wal_level = logical
        #max_wal_sender = 10
        #max_worker_processes = 8
        #max_logical_replication_workers = 4
        #max_sync_workers_per_subscription = 2
		
		# Alter user toto WITH REPLICATION;

        #verification
        local port=$(pgport $1)
        local host="`hostname`"
        local subcription_name="$sub_${ins}"

        local reqTableIncluded="select string_agg(tab.table_schema || '.' || tab.table_name, ', ')
from information_schema.tables tab
left join information_schema.table_constraints tco
on tab.table_schema = tco.table_schema
and tab.table_name = tco.table_name
where   tco.constraint_type = 'PRIMARY KEY' and
        tab.table_type = 'BASE TABLE' and 
        tab.table_schema not in ('pg_catalog', 'information_schema') and 
        tco.constraint_name is not null and 
        tab.table_schema='$schema'"

        echo "-- Chaine de creation de la PUBLICATION  - On supprime s'il existe
DROP PUBLICATION IF EXISTS ${publication_name} CASCADE ;"

        if [ "$excl_patterns" == "ALL" ]; then
            echo "CREATE PUBLICATION  ${publication_name} FOR ALL TABLES;"
        else
            for pat in $(echo $excl_patterns | sed "s/,/ /g"); do
                    reqTableIncluded="$reqTableIncluded and tab.table_name NOT LIKE '$pat'"
            done
            reqTableIncluded="$reqTableIncluded  order by 1"
            echo "$reqTableIncluded" | while IFS= read -r line
            do
                echo "-- $line"
            done
            #On recherche toutes les tables du schema ayant au moins une PK
            all_tables=$(psql -p $port -d $db -Ant -c "$reqTableIncluded")
            
            echo "CREATE PUBLICATION  ${publication_name} FOR TABLE ${all_tables} ;"
        fi

echo "-- Chaine de creation de la SUBSCRIPTION
-- DROP SUBSCRIPTION IF EXISTS  ${subcription_name}  CASCADE  ;
-- CREATE SUBSCRIPTION ${subcription_name} CONNECTION 'host=$host port=$port dbname=$db user=xxxx password=xxxxx' PUBLICATION ${publication_name};"
}

spggenpublication() 
{
    pggenpublication $1 $1 $1 ${1}pub wrf%,datachangelog%,databasechangelog%
}

pgaqueries()
{
     psql -p $(pgport $1) -U postgres ${2:-"$1"} -c "select pid, usename || '@' || datname as user, application_name, \
     TO_CHAR(now()-query_start,'DD')||'j '||TO_CHAR(now()-query_start,'HH24:MI:SS') as duration, \
     split_part(client_hostname, '.', 1) || '(' || client_addr || ')' AS from, \
     left(query,80) as query from pg_stat_activity where state='active' and query NOT ILIKE '%pg_stat_activity%'"
}
pgbckqueries()
{
    query="select pid, state, usename || '@' || datname as user, application_name, \
     TO_CHAR(now()-query_start,'DD')||'j '||TO_CHAR(now()-query_start,'HH24:MI:SS') as duration, \
     split_part(client_hostname, '.', 1) AS hostname_from, client_addr AS ip_from, \
     left(query,80) as query from pg_stat_activity"
    [ -n "$3" ] && query="$query where pid=$3"
     query="$query ORDER BY state, duration desc"
    psql -p $(pgport $1) -U postgres ${2:-"$1"} -c "$query"
}


pgoldestquerypid()
{
    query="select pid, now()-query_start as duration  from pg_stat_activity where state='active' ORDER BY duration desc LIMIT 1"
    pgrawpsql  $1 "$query"
}

pgcancelbck()
{
    pgbckqueries $*
    psql -p $(pgport $1) -U postgres ${2:-"$1"} -c "select pg_cancel_backend($3);"
}
pgcancellastbck()
{
    pgnormalmode
    local infopid=$(pgoldestquerypid $*)
    info "* PID TO CANCEL: $infopid"
    local pid=$(echo $infopid | perl -pe 's/(.*)\|.*/$1/g')
    pgcancelbck $1 $1 $pid
    title1 "Apres"
    pgbckqueries $*
}

pgkillbck()
{
    pgbckqueries $*
    psql -p $(pgport $1) -U postgres ${2:-"$1"} -c "select pg_terminate_backend($3);"
}

pgkilllastbck()
{
    pgnormalmode
    local infopid=$(pgoldestquerypid $*)
    info "* PID TO CANCEL: $infopid"
    local pid=$(echo $infopid | perl -pe 's/(.*)\|.*/$1/g')
    pgkillbck $1 $1 $pid
    title1 "Apres"
    pgbckqueries $*
}

pgclongestquery()
{
    pgcancelbck $1 $1 $(pgbckqueries $1| grep active | head -n1 | cut -d\| -f1)
}

pglockinfo()
{
     echo "select l.pid, 
     count(*) as nblocks, 
     (select usename from pg_stat_activity where pid=l.pid), 
     (select application_name from pg_stat_activity where pid=l.pid), 
     (select datname from pg_stat_activity where pid=l.pid),
     (select client_hostname from pg_stat_activity where pid=l.pid), 
     (select client_addr from pg_stat_activity where pid=l.pid), 
     (select waiting from pg_stat_activity where pid=l.pid), 
     (select state from pg_stat_activity where pid=l.pid), 
     (select TO_CHAR(now()-query_start,'DD')||'j '||TO_CHAR(now()-query_start,'HH24:MI:SS') AS duree_bloquage from pg_stat_activity where pid=l.pid)
     from pg_locks l  
     group by l.pid
     ORDER BY nblocks DESC;"| psql -p $(pgport $1) -U postgres ${2:-"$1"}
}

pglockinginfo()
{

echo "\x
SELECT
nom_base,
schema_objet_locke,
nom_objet_locke,
type_objet_locke,
duree_bloquage,
pid_session_bloquante,
user_session_bloquante,
client_session_bloquante,
derniere_requete_session_bloquante,
heure_debut_session_bloquante,
heure_debut_requete_bloquante,
pid_session_bloquee,
user_session_bloquee,
client_session_bloquee,
derniere_requete_session_bloquee,
heure_debut_requete_bloquee,
heure_debut_session_bloquee
FROM 
(
SELECT distinct 
RANK() OVER (PARTITION BY c.pid ORDER BY g.query_start DESC) as rang,
c.datname AS nom_base, 
e.nspname AS schema_objet_locke,
d.relname AS nom_objet_locke,
CASE 
WHEN d.relkind IN ('t','r') THEN 'table' 
WHEN d.relkind = 'i' THEN 'index' 
WHEN d.relkind = 's' THEN 'sequence' 
WHEN d.relkind = 'v' THEN 'vue' 
ELSE d.relkind::text 
END AS type_objet_locke,
TO_CHAR(now()-c.query_start,'DD')||'j '||TO_CHAR(now()-c.query_start,'HH24:MI:SS') AS duree_bloquage,
g.pid AS pid_session_bloquante,
g.usename AS user_session_bloquante,
g.client_addr AS client_session_bloquante, 
g.query AS derniere_requete_session_bloquante, 
TO_CHAR(g.backend_start,'YYYYMMDD HH24:MI:SS') AS heure_debut_session_bloquante,
TO_CHAR(g.query_start,'YYYYMMDD HH24:MI:SS') AS heure_debut_requete_bloquante,
c.pid AS pid_session_bloquee, 
c.usename AS user_session_bloquee,
c.client_addr AS client_session_bloquee, 
c.query AS derniere_requete_session_bloquee, 
TO_CHAR(c.query_start,'YYYYMMDD HH24:MI:SS') AS heure_debut_requete_bloquee,
TO_CHAR(c.backend_start,'YYYYMMDD HH24:MI:SS') AS heure_debut_session_bloquee
FROM 
pg_locks AS a,
pg_locks AS b,
pg_stat_activity AS c,
pg_class AS d,
pg_namespace AS e,
pg_locks AS f,
pg_stat_activity AS g
WHERE a.pid = b.pid
AND a.pid = c.pid
AND b.relation = d.oid
AND d.relnamespace = e.oid
AND b.relation = f.relation
AND b.pid <> f.pid
AND f.pid = g.pid
AND c.query_start >= g.query_start
AND a.granted IS FALSE
AND b.relation::regclass IS NOT NULL
AND e.nspname NOT IN ('pg_catalog','pg_toast','information_schema')
AND e.nspname NOT LIKE 'pg_temp_%'
AND f.granted is true
) AS resultat
WHERE rang = 1
ORDER BY resultat.heure_debut_requete_bloquee,resultat.heure_debut_requete_bloquante ;" | psql -p $(pgport $1) -U postgres ${2:-"$1"}
}

pglcopydb()
{
    local ins=$1
    local sdb=${2:-"$ins"}
    local tdb=$3
    local force=${4:-"noforce"}

    pgdbs $ins | grep -Eq "^${sdb}$"
    if [ $? -ne 0 ]; then
        error "SOURCE DB $sdb doesnt exist"
        return 1
    fi
    set +x 
    if [ "$force" == "force" ];then
        echo "SELECT * FROM pg_stat_activity WHERE datname = '${tdb}';
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${tdb}';
DROP DATABASE IF EXISTS $tdb;
COMMIT;" | psql  -aeE -p $(pgport $ins)
    else
            echo "DROP DATABASE IF EXISTS $tdb - NO EXECUTED"
    fi
    set -x
    pgdbs $ins | grep -Eq "^${tdb}$"
    if [ $? -eq 0 ]; then
        echo "TARGET DB $tdb exists"
        return 2
    fi
    pgdbs $ins
    date
    echo "CREATE DATABASE $tdb;" | psql -aeE -p $(pgport $ins)
    pg_dump -p $(pgport $ins) -v -d $sdb | time psql -p $(pgport $ins) $tdb
    date
}

pggenhba()
{
    echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD

# local is for Unix domain socket connections only
local   all             all                                     trust

# IPv4 local connections:
host    all             all             127.0.0.1/32            md5

# IPv6 local connections:
host    all             all             ::1/128                 md5

# Allow replication connections from localhost, by a user with the
# replication privilege.

host    all             check_pgactivity  192.168.0.252/32    md5  # Machine test
host    all             check_pgactivity  0.0.0.0/0             reject

host     replication    replication       0.0.0.0/0             md5
host    all             all               0.0.0.0/0             md5" > /admin/scripts/pg_hba.conf

chown postgres. /admin/scripts/pg_hba.conf
chmod 750 /admin/scripts/pg_hba.conf
}

pgupdatehba()
{
    local $ins=$1
    [ -z "$1" ] && return 127
    local hordate=$(date "+%Y-%m-%d_%H-%M-%S")
    PGDATA=$(psql -p $(pgport $ins) -U postgres -Ant -c "show data_directory")

    if [ ! -f "$PGDATA/pg_hba.conf" ]; then
        echo " Pas de fichier $PGDATA/pg_hba.conf"
        return 1
    fi
    if [ ! -f "/admin/scripts/pg_hba.conf" ]; then
        echo "Utilisez pggenhba pour générer /admin/scripts/pg_hba.conf"
        return 2
    fi


    echo "Changement du fichier hba pour l'instance $ins avec PGDATA = $PGDATA"

    mv $PGDATA/pg_hba.conf $PGDATA/pg_hba.conf.${hordate}
    
    cp /admin/scripts/pg_hba.conf $PGDATA/pg_hba.conf
    chown postgres. /admin/scripts/pg_hba.conf
    chmod 750 /admin/scripts/pg_hba.conf

    pg_ctl -D $PGDATA reload
    echo "=============================================================================="
    cat $PGDATA/pg_hba.conf
}

#=============================================================================== 
# Gets a quantity of seconds and formats the output into Days, Hours, Minutes and seconds
# 
# @parm Seconds
# @return string containing days, hours Minutes and seconds example: 0D 0H 0M 1S 
#
# dependencies:none
#
#=============================================================================== 
secToDaysHoursMinutesSeconds()
{
local seconds=$1
local days=$(($seconds/86400))
seconds=$(($seconds-($days*86400) ))
local hours=$(($seconds/3600))
seconds=$((seconds-($hours*3600) ))
local minutes=$(($seconds/60))
seconds=$(( $seconds-($minutes*60) ))
echo -n "${days}d:${hours}h:${minutes}m:${seconds}s"
}

#=============================================================================== 
# Gets the age of a file in seconds
# 
# @parm a file name (example: /etc/hosts
# @return Age in seconds 
#
# dependencies:none
#
#=============================================================================== 
fileAge()
{
echo $((`date +%s` - `stat -c %Z $1`)) 
}

humanFileAge()
{
    echo $(secToDaysHoursMinutesSeconds $(fileAge $1) )
}

findFileOlderThanDays()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f -mtime +${2:-"10"}
}

findFileOlderThanMins()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f -mmin +${2:-"10"}
}

getLatestNFiles()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f -printf "%T+\t%p\n" | sort -r |head -n ${2:-"1000"} | awk '{print $2}'
}

getHLatestNFiles()
{
    getLatestNFiles $* | xargs -n 1 ls -lsh
}

getOldestNFiles()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f -printf "%T+\t%p\n" | sort |head -n ${2:-"1000"} | awk '{print $2}'
}

getHOldestNFiles()
{
    getOldestNFiles $* | xargs -n 1 ls -lsh
}

getAllFiles()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f -printf "%T+\t%p\n" | sort | awk '{print $2}'
}

getHAllFiles()
{
    getAllFiles $* | xargs -n 1 ls -lsh
}

getNbFiles()
{
    find ${1:-"."} -maxdepth ${3:-"1"} -type f | wc -l
}

getOldestFilesToKeepNLastFiles()
{
    local nbFile=$(find ${1:-"."} -maxdepth ${3:-"1"} -type f|wc -l)
    if [ $nbFile -gt ${2:-1000} ]; then
        local nbTargetFile=$(( $nbFile - ${2:-1000} ))
        find ${1:-"."} -maxdepth ${3:-"1"} -type f -printf "%T+\t%p\n" | sort |head -n +$nbTargetFile | awk '{print $2}'
    fi
}

getHOldestFilesToKeepNLastFiles()
{
    getOldestFilesToKeepNLastFiles $* | xargs -n 1 ls -lsh
}


listAllIncomingTcpPortsRules()
{
    /sbin/iptables -L INPUT -n -v
}

blockIncomingTcpPorts()
{
    for port in $*; do
        /sbin/iptables -A INPUT -p tcp --dport $port -j DROP
    done
    listAllIncomingTcpPortsRules
}

unblockAllIncomingTcpPorts()
{
    /sbin/iptables -F INPUT -v
    listAllIncomingTcpPortsRules
}

pgnormalmode()
{
    unset PAGER
}

pspgmode()
{
    export PAGER="pspg -s 0" 
}

pggetinstancepaths()
{
    local ins=$1
    [ -z "$1" ] && return 127
    (
        psql -p $(pgport $ins) -U postgres -Ant -c "show data_directory"
        psql -p $(pgport $ins) -U postgres -Ant -c "SELECT pg_catalog.pg_tablespace_location(oid) FROM pg_catalog.pg_tablespace" 
        psql -p $(pgport $ins) -U postgres -Ant -c "SELECT pg_catalog.pg_tablespace_location(oid) FROM pg_catalog.pg_tablespace" ${2:-"$ins"}
    ) | sort | uniq | xargs
}

pgtarinstance()
{
    local ins=$1
    local hordate=$(date "+%Y-%m-%d_%H-%M-%S")
    [ -z "$1" ] && return 127
    local PGDATA=$(psql -p $(pgport $ins) -U postgres -Ant -c "show data_directory")
    pg_ctl -D $PGDATA status
    local backupDirs="$(pggetinstancepaths $ins)"
    local targetTar=/backups/${ins}_${hordate}.tgz
    #pg_ctl -D $PGDATA stop 
    psql -p $(pgport $ins) -U postgres -Ant -c "show data_directory"
    time tar czf $targetTar --exclude='*/pg_log/*' --exclude='*/log/*' $backupDirs /etc/systemd/system/postgresql-*${ins}.service
    if [ $? -ne 0 ]; then
        echo "Creation $targetTar FAILED"
        return 3
    fi
    pg_ctl -D $PGDATA start
    tar tzf $targetTar
    if [ $? -ne 0 ]; then
        echo "Verification $targetTar FAILED"
        return 3
    fi
    sha256sum $targetTar > ${targetTar}.sha256sum
    ls -lsh $targetTar
    sha256sum -c ${targetTar}.sha256sum
    return $?
}

pgstartbackup()
{
    local ins=$1
    local label=${2:-"default"}
    [ -z "$1" ] && return 127
    psql -p $(pgport $ins) -U postgres -Ant -c "select pg_start_backup('$label')"
}
pgstopkbackup()
{
    local ins=$1
    local label=${2:-"default"}
    [ -z "$1" ] && return 127
    psql -p $(pgport $ins) -U postgres -Ant -c "select pg_stop_backup()"
}

confirm()
{
    [ "$ASSUME_YES" = "yes" ] && return 0
    title1 "$*"
    read -p "Continue (y/n)?" choice
    case "$choice" in 
      y|Y ) 
        echo "yes"
        return 0
        ;;
      n|N ) echo "no";;
      * ) echo "invalid";;
    esac
    return 1
}

pgreport()
{
    local horodate=$(date "+%Y-%m-%d_%H-%M-%S")
    local label=${1:-"$horodate"}
    shift
    local params="$*"

    local targetDir="/tmp/reports/$label"
    if [ -d "$targetDir"  -a -z "$FORCE" ];then
        error "Problem $targetDir EXISTS"
        return 127
    fi

    rm -rf $targetDir
    mkdir -p $targetDir

	pguser $params | sort > $targetDir/users.txt
    pguserdbs $params | sort > $targetDir/userdbs.txt

    for db in $(pguserdbs $params); do
        mkdir  -p $targetDir/$db
        info "Exploring DATABASE: $db"
        pgtables $params $db | sort > $targetDir/$db/tables.txt
        info "GENERATING $targetDir/$db/tables.txt"
        for schema in $(pgschemas $params $db); do
            mkdir -p $targetDir/$db/$schema
            echo "EXPLORING DATABASE SCHEMA: $db / $schema"
            pgtables $params $db | grep -E "^${schema}\." | sort > $targetDir/$db/$schema/tables.txt
            info "GENERATING $targetDir/$db/$schema/tables.txt"
            pgtables $params $db | grep -Ec "^${schema}\." > $targetDir/$db/$schema/nbtables.txt
            info "GENERATING $targetDir/$db/$schema/nbtables.txt"
            pgscountlines $schema $params $db > $targetDir/$db/$schema/linetables.txt
            info "GENERATING $targetDir/$db/$schema/linetables.txt"
            pgviews $schema $params $db  | sort > $targetDir/$db/$schema/views.txt
            info "GENERATING $targetDir/$db/$schema/views.txt"
            pgmatviews $schema $params $db  | sort > $targetDir/$db/$schema/matviews.txt
            info "GENERATING $targetDir/$db/$schema/matviews.txt"
        done
    done
}


pguser()
{
	psql $* -Ant -c "SELECT usename from pg_user where usename not in ('postgres', 'replication', 'lreplication', 'sreplication', 'check_pgactivity')"
}

pguserdbs()
{
      psql $* -lAnt | grep '|' | cut -d'|' -f1 | grep -Ev 'postgres|template(0|1)'
}

pgtables()
{
	psql $* -Ant -c "select schemaname || '.' || tablename from pg_tables where schemaname NOT IN ('information_schema' , 'pg_catalog')"
}

pgschemas()
{
	psql $* -Ant -c "SELECT nspname FROM pg_catalog.pg_namespace where nspname NOT IN ('information_schema') AND nspname NOT LIKE 'pg_%'"
}

pgscountlines()
{
	pgcountlines $* | sort -nr -k2
}

pgcountlines()
{
	local schema=$1
	shift
	for tbl in $(psql $* -tA -c "select tablename from pg_tables where schemaname='${schema}' order by tablename"); do
		echo -ne "$tbl\t"
		psql $* -tA -c "select count(*) from ${schema}.$tbl"
	done
}

pgviews()
{
    local schema=$1
	shift
	psql $* -Ant -c "select schemaname || '.' || viewname from pg_views where schemaname = '${schema}'"
}

pgmatviews()
{
    local schema=$1
	shift
	psql $* -Ant -c "select schemaname || '.' || matviewname from pg_matviews where schemaname = '${schema}'"
}

check_diff_reports()
{
	diff -ra --side-by-side /tmp/reports/{$1,$2}
	info "Code REtour: $?"
}