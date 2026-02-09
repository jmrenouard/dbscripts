#!/bin/bash

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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

banner "BEGIN SCRIPT: ${_NAME}"
lRC=0

#creation du point de montage
mkdir /mnt/glusterfs
#ajout de notre point de montage à /etc/fstab afin qu'il soit actif au démarrage de notre serveur
cat << 'EOL' |  tee -a /etc/fstab
127.0.0.1:/glustervol1 /mnt/glusterfs glusterfs defaults,_netdev 0 0
EOL
#montage de notre système
mount /mnt/glusterfs
#creation de notre dossier pour le volume docker
cmd "mkdir -p /mnt/glusterfs/docker_volume/mariadb"

footer "END SCRIPT: ${_NAME}"
exit $lRC

