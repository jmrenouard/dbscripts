#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"
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

footer "END SCRIPT: $NAME"
exit $lRC
