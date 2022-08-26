#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

inter=${1:-"eth1"}
latms=${2:-"10000"}
durs=${3:-"200"}

if [ "$1" = "install" ]; then
	yum -y install iproute-tc kernel-modules-extra
	exit $?
fi

( 
	set -x
	tc qdisc add dev $inter root netem delay ${latms}ms; 
	sleep ${durs}s; 
	tc qdisc del dev $inter root
) &