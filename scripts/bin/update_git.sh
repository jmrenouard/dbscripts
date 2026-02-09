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

TARGET_DIR="/logiciels/datastax/zeppelin/notebook"
banner "UPDATING GIT REPOSITORY AT $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    error "Directory $TARGET_DIR not found"
    exit 1
fi

cd "$TARGET_DIR"

cmd "git status" "CHECKING GIT STATUS"

info "Cleaning deleted notebooks"
NBRM=$(git status | grep -E "(supprim|deleted)\s*:"|wc -l)
if [ "$NBRM" -gt 0 ]; then
	cmd "git status | grep -E \"(supprim|deleted)\s*:\" |cut -d: -f2 | xargs -n1 git rm -f" "REMOVING DELETED FILES"
else
	info "Nothing to delete"
fi

info "Adding modified notebooks"
NBUP=$(git status | grep -E 'modifi.*:'|wc -l)
if [ "$NBUP" -gt 0 ]; then
	cmd "git status | grep -E 'modifi.*:' | cut -d: -f2 | xargs -n 1 git add" "ADDING MODIFIED FILES"
else
	info "Nothing to update"
fi

cmd "git add *" "ADDING ALL REMAINING FILES"
cmd "git commit -m \"Newly updates Zeppelin notebook at $(date +%Y%m%d-%H%M%S)\"" "COMMITTING CHANGES"
cmd "git push" "PUSHING TO REMOTE"

footer "GIT UPDATE"
