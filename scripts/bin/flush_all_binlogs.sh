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

[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf

nbHour=$1

# taille max d'un fichier binaire MariaDB (binlog)
# max_binlog_size
# log_bin_compress
# wsrep_max_ws_size

# FLUSH BINARY LOGS BEFORE (NOW() -12 HOUR);
if [ -n "$nbHour" ]; then
	mysql -v -e "FLUSH BINARY LOGS BEFORE (NOW() - $nbHour HOUR);"
else		
	title2 "FLUSHING BINARY LOGS"
	mysql -v -e "FLUSH BINARY LOGS;"

	title2 "GETTING LAST BINLOG FILE"
	last_binlog=$(mysql -Nrs  -e'show binary logs' | sort -nr| head -n 1 | awk '{print $1}')
	info "Last binlog: $last_binlog"

	title2 "REMOVING ALL PREVIOUS BIN LOG"

	mysql -v  -e " PURGE BINARY LOGS TO '$last_binlog'" 
fi

title2 "CURRENT BINARY LOG"
mysql -e 'show binary logs'
