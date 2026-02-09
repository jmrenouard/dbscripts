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
[ -f "/etc/profile.d/docker.sh" ] && source /etc/profile.d/docker.sh

lRC=0

title1 "PROVISIONNING DOCKER PORTAINER"
sudo systemctl start podman
sudo systemctl enable podman

sudo docker volume create portainer_data

echo -n "portainer" > /var/tmp/portainer_password

sudo docker ps -a |grep "portainer-ce" | awk '{print $1}'| xargs -n 1 sudo docker rm -f

sudo docker run -d -p 9000:9000 -p 8000:8000 \
--name=portainer --restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
-v /var/tmp/portainer_password:/var/tmp/portainer_password portainer/portainer-ce \
--admin-password-file /var/tmp/portainer_password

