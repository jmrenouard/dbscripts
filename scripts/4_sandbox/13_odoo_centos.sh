#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

banner "BEGIN SCRIPT: $_NAME"
# Install the repository RPM:
cmd "yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

# Install PostgreSQL:
cmd "yum install -y postgresql14-server"

# Optionally initialize the database and enable automatic start:
cmd "/usr/pgsql-14/bin/postgresql-14-setup initdb"
cmd "systemctl enable postgresql-14"
cmd "systemctl start postgresql-14"

cmd "yum install -y yum-utils"

cmd "yum-config-manager --add-repo=https://nightly.odoo.com/16.0/nightly/rpm/odoo.repo"

cmd "yum install -y odoo"

cmd "systemctl enable odoo"

cmd "systemctl start odoo"

footer "BEGIN SCRIPT: $_NAME"
exit $lRC