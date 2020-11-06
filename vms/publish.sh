#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)

BOX="virtualbox.box"
CLOUD_BOX=jmrenouard/centos8
VERSION=8.0.2

[ -f ".envtoken" ] && $VAGRANT cloud auth login --token=$(cat .envtoken)
set -x
rm -f $BOX
$VAGRANT package --output $BOX
MD5SUM_BOX=$(md5sum $BOX|awk '{print $1}')

$VAGRANT cloud box show $CLOUD_BOX

$VAGRANT cloud publish $CLOUD_BOX $VERSION \
 virtualbox $BOX -d "Version v$VERSION" --release --version-description "Version from $(date)" \
--clean --checksum-type md5 --checksum $MD5SUM_BOX

#$VAGRANT cloud version release $CLOUD_BOX $VERSION

