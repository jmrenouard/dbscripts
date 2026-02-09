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
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

lRC=0
defaultPassword="elastic"
banner "BEGIN SCRIPT: ${_NAME}"

title1 "STEP 1: INSTALL AND CONFIGURE KIBANA"
cmd "dnf -y install java-1.8.0-openjdk"
[ $? -ne 0 ] && exit 127

cmd "dnf -y update"
[ $? -ne 0 ] && exit 127

cmd "dnf -y install kibana"
[ $? -ne 0 ] && exit 127


cmd "/bin/systemctl daemon-reload"

cmd "/bin/systemctl enable kibana.service"

sed -i -e "/server.host/d" \
-e "/server.name/d" \
-e "/elasticsearch.hosts/d" \
-e "/elasticsearch.username/d" \
-e "/elasticsearch.password/d" \
/etc/kibana/kibana.yml
[ $? -ne 0 ] && exit 127
echo "
server.host: 0.0.0.0
server.name: \"Test Kibana Server\"

elasticsearch.hosts: [ \"http://localhost:9200\" ]
elasticsearch.username: \"elastic\"
elasticsearch.password: \"elastic\"" >>/etc/kibana/kibana.yml

firewall-cmd --zone=public --permanent --add-port=5601/tcp
firewall-cmd --zone=public --permanent --add-port=9200/tcp

cmd "/bin/systemctl restart kibana.service"

info "ACEESS to http://${my_private_ipv4}:5601/ elastic/alastic"
footer "END SCRIPT: ${_NAME}"
exit $lRC

