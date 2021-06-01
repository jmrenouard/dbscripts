#!/bin/bash

set -x
id
whoami
hostname -a
pwd
SRV=$1

SSH_CMD="ssh -o StrictHostKeyChecking=no ${SRV}"

$SSH_CMD "reboot" & 

sleep 5s
i=0

while [ $i -lt 10 ]; do
	$SSH_CMD -q exit 
	if [ $? -eq 0 ]; then
		echo "$SRV IS UP AND RUNNING"
		exit 0
	fi
	echo "."
	sleep 3s
	i=$(($i + 1))
done
echo "$SRV IS NOT REBOOTED AFTER 31 s"
exit 3


