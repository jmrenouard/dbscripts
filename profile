#!/bin/bash

if [ "$0" != "-/bin/bash" -a "$0" != "/bin/bash" -a "$0" != "-bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
else
	_DIR="$(readlink -f ".")"
fi
[ "$(pwd)" = "$HOME" -o ! -f "./profile" ] && export _DIR="$HOME/dbscripts/"

export VMS_DIR="$(readlink -f ".")/vms"
[ -d "${_DIR}/../vms" ] && export VMS_DIR="${_DIR}/../vms"
[ -d "${_DIR}/vms" ] && export VMS_DIR="${_DIR}/vms"
[ -z "$DEFAULT_PRIVATE_KEY" ] && export DEFAULT_PRIVATE_KEY="$_DIR/vms/id_rsa"

export proxy_vms="proxy1,proxy2"
export db_vms="dbsrv1,dbsrv2,dbsrv3"
export app_vms="app1"
#export all_vms="app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"
export all_vms="app1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"

for module in utils git network slack vagrant linode vagrant;do
    [ -f "${module}.sh" ] && source ${module}.sh
done

