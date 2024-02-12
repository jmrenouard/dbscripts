#!/bin/bash
#export VAGRANT_EXPERIMENTAL="disks"
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)
$VAGRANT up --provider=virtualbox --no-provision $*
