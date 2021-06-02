#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

inter=${1:-"eth1"}
bw=${2:-"1kbps"}
durs=${3:-"200"}

if [ "$1" = "install" ]; then
	yum -y install iproute-tc kernel-modules-extra
	exit $?
fi

( 
	set -x
	tc qdisc add dev ${inter} handle 1: root htb default 11
    tc class add dev ${inter} parent 1: classid 1:1 htb rate ${bw}
	tc class add dev ${inter} parent 1:1 classid 1:11 htb rate ${bw}

	sleep ${durs}s; 
	tc qdisc del dev ${inter} root
) &