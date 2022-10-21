#!/bin/bash

if [ "$0" != "-/bin/bash" -a "$0" != "/bin/bash" -a "$0" != "-bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
else
	_DIR="$(readlink -f ".")"
fi
[ "$(pwd)" = "$HOME" -o ! -f "./profile" ] && export _DIR="$HOME/dbscripts/"

export VMS_DIR="$(readlink -f ".")/vm-vagrant"
[ -d "${_DIR}/../vms" ] && export VMS_DIR="${_DIR}/../vm-vagrant"
[ -d "${_DIR}/vms" ] && export VMS_DIR="${_DIR}/vm-vagrant"
[ -z "$DEFAULT_PRIVATE_KEY" ] && export DEFAULT_PRIVATE_KEY="$_DIR/vms/id_rsa_vm"

export proxy_vms="loadb0,loadb1"
export db_vms="node0,node1,node2"
export app_vms="app1"
export docker_vms="docker0,docker1,docker2"
#export all_vms="app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"
export all_vms="$proxy_vms,$db_vms,$app_vms"

for module in utils git network slack vagrant linode vagrant;do
    [ -f "${module}.sh" ] && source ${module}.sh
done
