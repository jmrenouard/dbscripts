#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)

#$VAGRANT cloud auth login --token=$1

rm -f centos8.box
$VAGRANT package --output  centos8.box
md5sum centos8.box

$VAGRANT cloud box show jmrenouard/centos8

$VAGRANT cloud publish jmrenouard/centos8 $2 virtualbox centos8.box -d "Version v$2"
