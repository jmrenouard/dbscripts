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

remotesrv=${1:-"dbsrv2"}
wsrep_param=${2:-"wsrep_sync_wait"}
wsrep_value=${3:-"0"}

echo "
drop database sync_wait; 
create database sync_wait;
use sync_wait;
create table tsync ( i int not null );
" | mysql -v -f

for i in {1..5000}; do
	echo "Bouche $i"
	mysql sync_wait -e "INSERT INTO tsync values ($i)"

	ret=$(mysql -h $remotesrv --batch sync_wait -e "set ${wsrep_param}=${wsrep_value};select i from tsync where i=$i")
	if [ "$ret" = "" ]; then
		echo "ERROR $i IS MISSING"
		exit 127
	fi
done
