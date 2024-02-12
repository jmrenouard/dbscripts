#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)
$VAGRANT destroy $*
[ -f "${1}_data.vdi" ] && rm -f ./${1}_data.vdi
[ -z "$1" ] && rm -f ./*_data.vdi