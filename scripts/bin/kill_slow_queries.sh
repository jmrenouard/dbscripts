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

mysql -e 'show processlist' | grep -v 'system user'| colunm -t

max_time=${1:-"0"}
for req in $(mysql -Nrs -B -e "select id from information_schema.processlist where user <> 'system user' and TIME >= '${max_time}'"); do 
	infos=$(mysql -Nrs -e "select * from information_schema.processlist where id=$req")
	if [ -n "$infos" ]; then
		ask_yes_or_no "KILLING $infos"
		[ $? -eq 0 ] && mysql -v -e "KILL $req"
	fi
done

#pt-kill --print --busy-time=5 --idle-time=5 --kill-query
