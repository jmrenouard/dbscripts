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
my_public_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)


lRC=0
banner "BEGIN SCRIPT: ${_NAME}"
PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"


cmd "$PCKMANAGER -y update" "UPDATE PACKAGE LIST"
lRC=$(($lRC + $?))

cmd "$PCKMANAGER -y upgrade" "UPDATE PACKAGES"
lRC=$(($lRC + $?))

cmd "$PCKMANAGER -y install openjdk-11-jre-headless wget" "INSTALL JRE JAVA"
lRC=$(($lRC + $?))

cmd "rm -f /var/tmp/rundeck-install.sh"

cmd "wget 'https://raw.githubusercontent.com/rundeck/packaging/main/scripts/deb-setup.sh' -O /var/tmp/rundeck-install.sh"
lRC=$(($lRC + $?))

cmd "bash /var/tmp/rundeck-install.sh rundeck" "INSTALL RUNDECK"
lRC=$(($lRC + $?))

cmd "$PCKMANAGER -y update" "UPDATE PACKAGE LIST"
lRC=$(($lRC + $?))

cmd "$PCKMANAGER -y install rundeck" "INSTALL RUNDECK"
lRC=$(($lRC + $?))

cmd " firewall-cmd --add-port=4440/tcp --permanent"
lRC=$(($lRC + $?))

cmd "systemctl status rundeckd"
lRC=$(($lRC + $?))

cmd "systemctl enable rundeckd"
lRC=$(($lRC + $?))

sed -i "s/localhost/$my_public_ipv4/g" /etc/rundeck/framework.properties /etc/rundeck/rundeck-config.properties

cmd "systemctl restart rundeckd"
lRC=$(($lRC + $?))

cmd "sleep 10s" "Attente 10s"

cmd "tail  /var/log/rundeck/service.log"

footer "END SCRIPT: ${_NAME}"
exit $lRC
