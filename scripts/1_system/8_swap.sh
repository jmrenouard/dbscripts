#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

swapfile="/swapfile"
swapsize="2G"
swapcount=1024
swapitemsize=2M

lRC=0
banner "BEGIN SCRIPT: $_NAME"

swapoff $swapfile ||true 

cmd "rm -f $swapfile" "REMOVE OLD SWAP FILE"

cmd "fallocate -l $swapsize $swapfile" "CREATE $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "dd if=/dev/zero of=$swapfile bs=$swapitemsize count=$swapcount" "ZEROING $swapfile SWAP FILE OF $swapsize"
lRC=$(($lRC + $?))

cmd "chmod 600 $swapfile" "SET PERMISSIONS FOR SWAP FILE"
lRC=$(($lRC + $?))

cmd "mkswap $swapfile" "FORMAT SWAP FILE"
lRC=$(($lRC + $?))

cmd "swapon $swapfile" "ENABLE SWAP FILE"
lRC=$(($lRC + $?))

sed -i "/swapfile/d" /etc/fstab
lRC=$(($lRC + $?))
info "REMOVE OLD SWAP FILE ENTRY FROM /etc/fstab"

echo "$swapfile none swap sw 0 0" >> /etc/fstab
cmd "grep '$swapfile' /etc/fstab" "ADD NEW SWAP FILE ENTRY TO /etc/fstab"
lRC=$(($lRC + $?))

cmd "swapon --show" "SHOW SWAP STATUS"
lRC=$(($lRC + $?))

cmd "free -h" "SHOW MEMORY STATUS"
lRC=$(($lRC + $?))

footer "END SCRIPT: $_NAME"
exit $lRC