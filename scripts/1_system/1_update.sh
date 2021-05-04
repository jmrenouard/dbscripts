#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0
banner "BEGIN SCRIPT: $_NAME"

PCKMANAGER="yum"
[ "$ID" = "ubuntu" -o "$ID" = "debian" ] && PCKMANAGER="apt"

cmd "$PCKMANAGER -y update" "UPDATE PACKAGE LIST"
lRC=$(($lRC + $?))

cmd "$PCKMANAGER -y upgrade" "UPDATE PACKAGES"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC