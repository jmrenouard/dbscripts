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

cmd "$PCKMANAGER -y install python3 perl firewalld net-tools" "INSTALL FIREWALLD"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC
