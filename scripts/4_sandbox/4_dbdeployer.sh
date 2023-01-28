#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0
VERSION=1.54.0
OS=linux
origin=https://github.com/datacharmer/dbdeployer/releases/download/v$VERSION

banner "BEGIN SCRIPT: $_NAME"

cd /var/tmp
wget $origin/dbdeployer-$VERSION.$OS.tar.gz
tar -xzf dbdeployer-$VERSION.$OS.tar.gz
chmod +x dbdeployer-$VERSION.$OS
mv dbdeployer-$VERSION.$OS /opt/local/bin/dbdeployer

footer "BEGIN SCRIPT: $_NAME"