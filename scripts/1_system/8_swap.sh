#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

swapfile="/swapfile"
swapsize="2G"

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "fallocate -l $swapsize $swapfile" "CREATE $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "dd if=/dev/zero of=$swapfile bs=$swapsize count=1" "ZEROING $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "chmod 600 $swapfile" "SET PERMISSIONS FOR SWAP FILE"
lRC=$(($lRC + $?))

cmd "mkswap $swapfile" "FORMAT SWAP FILE"
lRC=$(($lRC + $?))

cmd "swapon $swapfile" "ENABLE SWAP FILE"
lRC=$(($lRC + $?))

cmd "sed -i "#$swapfile/d" /etc/fstab" "REMOVE OLD SWAP FILE ENTRY FROM /etc/fstab"
lRC=$(($lRC + $?))

cmd "echo '$swapfile none swap sw 0 0' >> /etc/fstab" "ADD NEW SWAP FILE ENTRY TO /etc/fstab"
lRC=$(($lRC + $?))

cmd "swapon --show" "SHOW SWAP STATUS"
lRC=$(($lRC + $?))

cmd "free -h" "SHOW MEMORY STATUS"
lRC=$(($lRC + $?))

footer "END SCRIPT: $_NAME"
exit $lRC