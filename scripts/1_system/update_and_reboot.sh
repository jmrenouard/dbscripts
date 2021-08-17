#!/bin/bash

SRV=$1
CYCLE=${2:-"10"}
SSH_CMD="ssh -v -o StrictHostKeyChecking=no ${SRV}"

$SSH_CMD "apt -y update"
$SSH_CMD "apt -y upgrade"


$SSH_CMD "reboot" & 

sleep 5s
i=0

while [ "$i" != "$CYCLE" ]; do
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


