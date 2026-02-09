#!/bin/bash

source /etc/os-release

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
    eval "$tcmd"
    local cRC=$?
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

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"

lRC=0

banner "BEGIN SCRIPT: ${_NAME}"
# Install the repository RPM:
cmd "yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

# Install PostgreSQL:
cmd "yum install -y postgresql14-server"

# Optionally initialize the database and enable automatic start:
cmd "/usr/pgsql-14/bin/postgresql-14-setup initdb"
cmd "systemctl enable postgresql-14"
cmd "systemctl start postgresql-14"

cmd "yum install -y yum-utils"

cmd "yum-config-manager --add-repo=https://nightly.odoo.com/16.0/nightly/rpm/odoo.repo"

cmd "yum install -y odoo"

cmd "systemctl enable odoo"

cmd "systemctl start odoo"

footer "END SCRIPT: ${_NAME}"
exit $lRC