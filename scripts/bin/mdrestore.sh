#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

[ -f '/etc/profile.d/utils.mysql.sh' ] && source /etc/profile.d/utils.mysql.sh

banner "RESTORING DB WITH MYLOADER"
BCK_DIR=/data/backups/mydumper
#GZIP_CMD="cat"
#GZIP_CMD="gzip -cd"
GZIP_CMD="pigz -cd"

[ -f "/etc/mdconfig.sh" ] && source /etc/mdconfig.sh

if [ "$1" = "-l" -o "$1" = "--list" ]; then
    ls -lsht $BCK_DIR
    exit 0
fi
if [ "$2" = "-l" -o "$2" = "--list" ]; then
    ls -lsht $BCK_DIR/$1/
    exit 0
fi
GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ACTIVATED"
    echo -e "\t* Disable Galera with wsrep_on=off in configuration file"
    echo -e "\t* Drop Galera Cache /var/lib/mysql/galera.cache"
    echo -e "\t* Restart MariaDB or MySQL (systemctl restart mysql)"
    echo -e "\t* Restart restore script $0 $*"
    #exit 1
fi

sourcedb="$1"
shift
dumpdir="$1"
shift
targetdb="$1"
shift

if [ -z "$sourcedb" ]; then
	title2 "SELECTING SOURCE DATABASE"
	select sourcedb in $(ls -1 $BCK_DIR)
	do
	# leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then
        break;
    fi

    # complain if no file was selected, and loop to ask again
    if [[ "$sourcedb" == "" ]]
    then
        echo "'$REPLY' is not a valid number"
        continue
    fi
    break
    done
fi
info "SOURCE DATABASE IS $sourcedb"

if [ -z "$dumpdir" ]; then
	title2 "SELECTING $sourcedb EXTRACTION"
	select dumpdir in $(ls -1 $BCK_DIR/$sourcedb| sort -nr)
	do
	# leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then
        break;
    fi

    # complain if no file was selected, and loop to ask again
    if [[ "$dumpdir" == "" ]]
    then
        echo "'$REPLY' is not a valid number"
        continue
    fi
    break
    done
    dumpdir=$BCK_DIR/$sourcedb/$dumpdir
fi
info "DATABASE EXTRACTION DIR IS $dumpdir"
if [ ! -d "$dumpdir" ]; then
    die "$dumpdir doesnt exist"
fi

if [ -z "$targetdb" ]; then
	ask_yes_or_no "Restore on $sourcedb database "
	[ $? -eq 0 ] && targetdb=$sourcedb
fi

if [ -z "$targetdb" ]; then
	echo -e
	read -p 'Target dabase name : ' targetdb
fi

info "TARGET DATABASE IS $sourcedb"

title1 "Command: time myloader \
--directory $dumpdir \
--verbose=3  \
--threads=$(nproc) \
--overwrite-tables \
--database $targetdb \
--source-db $sourcedb \
--socket $(global_variables socket) \
--purge-mode DROP $*"

time myloader \
--directory $dumpdir \
--verbose=3  \
--threads=$(nproc) \
--overwrite-tables \
--database $targetdb \
--source-db $sourcedb \
--socket $(global_variables socket) \
--purge-mode DROP $*

lRC=$?
[ $lRC -eq 0 ] && ok "RESTORE OK"
cmd "db_list"
cmd "db_tables $targetdb"

info "FINAL CODE RETOUR: $lRC"
footer "RESTORING DB WITH MYLOADER"
exit $lRC
