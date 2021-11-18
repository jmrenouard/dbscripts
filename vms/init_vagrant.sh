#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)

if [ "$1" = "check" ] ;then
	$VAGRANT plugin list
	exit 0
fi

$VAGRANT plugin install vagrant-vbguest
$VAGRANT plugin install vagrant-hostmanager
$VAGRANT plugin install vagrant-persistent-storage

dnf -y install dkms kernel-devel
