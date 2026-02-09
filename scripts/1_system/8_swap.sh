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
swapfile="/swapfile"
swapsize="2G"
swapcount=1024
swapitemsize=2M

lRC=0
banner "BEGIN SCRIPT: ${_NAME}"

swapoff $swapfile ||true 

cmd "rm -f $swapfile" "REMOVE OLD SWAP FILE"

cmd "fallocate -l $swapsize $swapfile" "CREATE $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "dd if=/dev/zero of=$swapfile bs=$swapitemsize count=$swapcount" "ZEROING $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "chmod 600 $swapfile" "SET PERMISSIONS FOR SWAP FILE"
lRC=$(($lRC + $?))

cmd "mkswap $swapfile" "FORMAT SWAP FILE"
lRC=$(($lRC + $?))

cmd "swapon $swapfile" "ENABLE SWAP FILE"
lRC=$(($lRC + $?))

sed -i "/swapfile/d" /etc/fstab
lRC=$(($lRC + $?))
info "REMOVE OLD SWAP FILE ENTRY FROM /etc/fstab"

echo "$swapfile none swap sw 0 0" >> /etc/fstab
info "ADD NEW SWAP FILE ENTRY TO /etc/fstab"

grep "$swapfile" /etc/fstab
lRC=$(($lRC + $?))

cmd "swapon --show" "SHOW SWAP STATUS"
lRC=$(($lRC + $?))

cmd "free -h" "SHOW MEMORY STATUS"
lRC=$(($lRC + $?))

footer "END SCRIPT: ${_NAME}"
exit $lRC