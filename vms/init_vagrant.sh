#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)
$VAGRANT plugin install vagrant-vbguest
$VAGRANT plugin install vagrant-hostmanager
$VAGRANT plugin install vagrant-persistent-storage

yum -y install dkms kernel-devel

