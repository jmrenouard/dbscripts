#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
source /etc/os-release

lRC=0
VERSION=${1:-"13"}

##title_en: Centos MariaDB 10.5 server installation
##title_fr: Installation du serveur MariaDB 10.5 sur OS Centos  
##goals_en: Package software installation for MariaDB / Related tools installation / Last security packages installation
##goals_fr: Installation des packages logiciels pour MariaDB / Installation des logiciels tiers relatif aux bases de données / Installation des dernières versions logicielles
force=0
banner "BEGIN SCRIPT: $_NAME"

if [ ! -d "/var/lib/pgsql/${VERSION}/data/base" ]; then
	cmd "/usr/pgsql-13/bin/postgresql-${VERSION}-setup initdb"
	lRC=$(($lRC + $?))
fi

cmd "systemctl enable postgresql-${VERSION}"
lRC=$(($lRC + $?))

cmd "systemctl start postgresql-${VERSION}"
lRC=$(($lRC + $?))

echo "ALTER SYSTEM SET listen_addresses TO '0.0.0.0';" |su - postgres -c "psql -Upostgres"

cmd "systemctl restart postgresql-${VERSION}"
lRC=$(($lRC + $?))

footer "END SCRIPT: $NAME"
exit $lRC