#!/bin/bash
set -x

IPV1=${1:-"10.151.212.20/24"}
BRC1=${2:-"10.151.212.255"}
INT1=${3:-"ens192"}

TYPE=${4:-"BACKUP"}
PRIORITY=${5:-"100"}
PASSWD=${6:-Utraldsd"}

rm -f /tmp/keepalived.conf
cat <<EOF >/tmp/keepalived.conf
vrrp_script check_haproxy { 
        #script "/usr/bin/killall -v -s HUP /usr/sbin/haproxy"
        #script "/usr/bin/systemctl restart haproxy"
        script "/bin/bash /admin/scripts/ka_service_check.sh"
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
   # Synchro de l'état des connexions entre les LB sur l'interface $INT1\
        
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
   notify "/bin/bash /admin/scripts/ka_service_notify.sh"
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
