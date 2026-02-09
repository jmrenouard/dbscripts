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
die() { error "$*"; exit 1; }
ask_yes_or_no() {
    read -p "$1 ([y]es or [n]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|Y|yes) echo "yes";return 0 ;;
        *)     echo "no"; return 1;;
    esac
}
# --- End of Utility Functions ---

# --- Configuration ---
BCK_DIR="${BCK_DIR:-"/data/backups/mariabackup"}"
TMP_DIR="${TMP_DIR:-"/data/backups/tmp"}"
DATADIR="${DATADIR:-"/var/lib/mysql"}"
GZIP_CMD="${GZIP_CMD:-"pigz -cd"}"

# Load external configs
[ -f "/etc/bootstrap.conf" ] && source /etc/bootstrap.conf
[ -f "/etc/mbconfig.sh" ] && source /etc/mbconfig.sh
lRC=0

banner "MARIABACKUP RESTORING DB"
if [ -f "/etc/mbconfig.sh" ]; then
    info "LOADING CONFIG FROM /etc/mbconfig.sh"
    source /etc/mbconfig.sh
fi
if  [ -n "$1" -a -f "/etc/mbconfig_$TARGET_CONFIG.sh" ]; then
    info "LOADING CONFIG FROM /etc/mbconfig_$TARGET_CONFIG.sh"
    source /etc/mbconfig_$TARGET_CONFIG.sh
fi
if [ "$1" = "-l" -o "$1" = "--list" ]; then
	ls -lsht $BCK_DIR
	exit 0
fi

GALERA_SUPPORT=$(galera_is_enabled)

if [ "$GALERA_SUPPORT" = "1" ]; then
    info "GALERA IS ACTIVATED"
    echo -e "\t* Disable Galera with wsrep_on=off in configuration file"
    echo -e "\t* Drop Galera Cache /var/lib/mysql/galera.cache"
    echo -e "\t* Restart MariaDB or MySQL (systemctl restart mysql)"
    echo -e "\t* Restart restore script $0 $*"
    exit 1
fi

DUMP_FILE=$1
if [ -z "$DUMP_FILE" ]; then
	echo "The following archives were found; select one:"
	PS3="Use number to select a file or 'stop' to cancel: "

	# allow the user to choose a file
	select DUMP_FILE in $BCK_DIR/*.xbstream.gz
	do
	    # leave the loop if the user says 'stop'
	    if [[ "$REPLY" == stop ]]; then
	    	break;
	    fi

	    # complain if no file was selected, and loop to ask again
	    if [[ "$DUMP_FILE" == "" ]]
	    then
	        echo "'$REPLY' is not a valid number"
	        continue
	    fi
	    break
	done
fi

if [ ! -f "$DUMP_FILE" ]; then
	warn "$DUMP_FILE doesnt exist"
	lRC=127
fi

if [ "$2" != "-f" -a "$2" != "--force" ]; then
	title1 "FILE TO RESTORE"
	ls -lsht $DUMP_FILE
	info "Do you really want to restore $DUMP_FILE ?"
	ask_yes_or_no
	if [ $? -ne 0 ];then
		lRC=127
		footer "MARIABACKUP RESTORING DB"
		die "CANCEL BY USER"
	fi
fi

info "Checking SHA256 SIGN file"
sha256sum -c ${DUMP_FILE}.sha256sum
lRC=$?

# now we can use the selected file
info "$DUMP_FILE will be restored"

[ -d "$TMP_DIR" ] || mkdir -p $TMP_DIR
rm -rf "$TMP_DIR/*"

info "CMD: $GZIP_CMD $DUMP_FILE | mbstream -x"
    cmd "cd $TMP_DIR && $GZIP_CMD $DUMP_FILE | mbstream -x" "EXTRACTING BACKUP STREAM"
    lRC=$?
    cmd "mariabackup --prepare --target-dir=$TMP_DIR" "PREPARING RESTORE"
    lRC=$?
fi

if [ "$lRC" -eq 0 ]; then
    cmd "systemctl stop mariadb" "STOPPING MARIADB"
    cmd "mv ${DATADIR} ${BCK_DIR}/sav_datadir_$(date +%Y%m%d-%H%M%S)" "ARCHIVING OLD DATADIR"
    cmd "rm -rf $DATADIR/*" "CLEANING UP DATADIR"
    cmd "mkdir -p ${DATADIR}" "RECREATING DATADIR"
    cmd "rsync -avz $TMP_DIR/* $DATADIR/" "RSYNCING RESTORED DATA"
    cmd "chown -R mysql.mysql $DATADIR" "FIXING PERMISSIONS"
    cmd "systemctl start mariadb" "STARTING MARIADB"
    [ $? -eq 0 ] && cmd "rm -rf $TMP_DIR" "CLEANUP TMP DIR"
fi

lRC=$?
[ "$lRC" -eq 0 ] && ok "MARIABACKUP RESTORE OK"

info "FINAL CODE RETOUR: $lRC"
footer "MARIABACKUP RESTORING DB"
exit $lRC