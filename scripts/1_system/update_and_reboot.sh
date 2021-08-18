#!/bin/bash

SRV=$1
CYCLE=${2:-"10"}
SSH_CMD="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SRV}"

rm -f /tmp/save_my.cnf
cp -p /etc/mysql/my.cnf /tmp/save_my.cnf
$SSH_CMD "apt -y update"
$SSH_CMD "apt -y upgrade"

diff /etc/mysql/my.cnf /tmp/save_my.cnf
if [ $? -ne 0 ];then
	mv /etc/mysql/my.cnf /etc/mysql/my.cnf.sav
	cp -p /tmp/save_my.cnf /etc/mysql/my.cnf
fi

$SSH_CMD "reboot" & 

sleep 5s
i=0

while [ $i -lt $CYCLE ]; do
	$SSH_CMD -q exit 
	if [ $? -eq 0 ]; then
		echo "$SRV IS UP AND RUNNING"
		exit 0
	fi
	echo "."
	sleep 3s
	i=$(($i + 1))
done
echo "$SRV IS NOT REBOOTED AFTER $((1 +$CYCLE * 3)) s"
exit 3


SRV_LST="ix1-bv-u18-DrivePPdriveBD-01.renater.fr
ix1-bv-u18-DrivePPdriveBD-02.renater.fr
ix1-bv-u18-DrivePPdriveBD-03.renater.fr"

for srv in $SRV_LST; do
	bash -x update_and_reboot.sh $srv 
	sleep 20s
done