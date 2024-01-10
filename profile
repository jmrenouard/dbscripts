#!/bin/bash

if [ "$0" != "-/bin/bash" -a "$0" != "/bin/bash" -a "$0" != "-bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
else
	_DIR="$(readlink -f ".")"
fi
[ "$(pwd)" = "$HOME" -o ! -f "./profile" ] && export _DIR="$HOME/GIT_REPOS/dbscripts"

export VMS_DIR="$(readlink -f ".")/vms"
[ -d "${_DIR}/../vms" ] && export VMS_DIR="${_DIR}/../vms"
[ -d "${_DIR}/vms" ] && export VMS_DIR="${_DIR}/vms"
[ -z "$DEFAULT_PRIVATE_KEY" ] && export DEFAULT_PRIVATE_KEY="$_DIR/vms/id_rsa"

export proxy_vms="proxy1,proxy2"
export db_vms="dbsrv1,dbsrv2,dbsrv3"
export app_vms="app1"
export docker_vms="docker0,docker1,docker2"
#export all_vms="app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"
export all_vms="$proxy_vms,$db_vms,$app_vms"

for module in utils git network slack vagrant linode vagrant;do
    [ -f "${_DIR}/${module}.sh" ] && source ${_DIR}/${module}.sh
done

if [ -d "/usr/local/go/bin" ]; then
export PATH=$PATH:/usr/local/go/bin
fi