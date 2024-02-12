#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0

banner "BEGIN SCRIPT: $_NAME"

wget -q -O - https://nightly.odoo.com/odoo.key | gpg --dearmor --yes -o /usr/share/keyrings/odoo-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/16.0/nightly/deb/ ./' | tee /etc/apt/sources.list.d/odoo.list

cmd "apt-get update"

cmd "apt-get -y install net-tools odoo"

cmd "systemctl enable odoo"

cmd "systemctl restart odoo"

cmd "systemctl status odoo"

cmd "netstat -ltpn"

footer "BEGIN SCRIPT: $_NAME"
exit $lRC