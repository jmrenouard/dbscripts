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

set -x
TYPE=${1:-"MASTER"}
PRIORITY=${2:-"100"}
SRV=${3:-"ka"}
IPV1=${4:-"192.168.33.180/24"}
BRC1=${5:-"192.168.33.255"}
INT1=${6:-"eth1"}

PASSWD=${7:-"Utraldsd"}

rm -f /tmp/keepalived.conf
cat <<EOF >/tmp/keepalived.conf
vrrp_script check_haproxy { 
        #script "/usr/bin/killall -v -s HUP /usr/sbin/haproxy"
        #script "/usr/bin/systemctl restart haproxy"
        script "/bin/bash /opt/local/bin/${SRV}_service_check.sh"
        interval 10 
        fall 2       # require 2 failures for KO
		rise 2       # require 2 successes for OK
} 

vrrp_instance VI_1 { 
   virtual_router_id 100 
   state $TYPE 
   priority $PRIORITY 
   # Check inter-load balancer toutes les 2 secondes 
   advert_int 2
   # Synchro de l'état des connexions entre les LB sur l'interface $INT1
        
   interface $INT1 
   # Authentification mutuelle entre les LB, identique sur les deux membres 
   authentication { 
        auth_type PASS 
 		auth_pass $PASSWD 
   } 
   # Interface réseau commune aux deux LB 
   virtual_ipaddress { 
        $IPV1 brd $BRC1 scope global 
   }
   track_script { 
       check_haproxy 
   } 
   notify "/bin/bash /opt/local/bin/${SRV}_service_notify.sh"
}
EOF

cat /tmp/keepalived.conf
  
[ -d "/etc/keepalived" ] || sudo mkdir -p /etc/keepalived
[ -f "/etc/keepalived/keepalived.conf" ] && sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

cp /tmp/keepalived.conf /etc/keepalived
chown root. /etc/keepalived/keepalived.conf

chmod 644 /etc/keepalived/keepalived.conf

systemctl enable keepalived 
systemctl restart keepalived
