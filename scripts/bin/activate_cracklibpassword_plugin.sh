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

banner "BEGIN SCRIPT: $_NAME"

title2 "CREATE CONFIG FILE FOR CRACKLIB PASSOWRD"
cmd "yum -y install MariaDB-cracklib-password-check cracklib cracklib-dicts"

echo "[mariadb]
plugin-load-add=cracklib_password_check
[mariadb]
plugin_load_add = server_audit
cracklib_password_check=FORCE_PLUS_PERMANENT

" | tee /etc/my.cnf.d/93_cracklib_password_plugin.cnf

title2 "RESTARTING MARIADB SERVER"
cmd "systemctl restart mariadb"
lRC=$(($lRC + $?))

title2 "INSTALLING CRACKLIB PASSWORD PLUGIN"
mysql  -v -e "INSTALL SONAME 'cracklib_password_check';"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC
