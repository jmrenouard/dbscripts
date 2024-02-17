#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"

lRC=0
banner "BEGIN SCRIPT: $_NAME"

cmd "systemctl stop mariadb"

[ -z "$DATADIR" ] && export DATADIR=/var/lib/mysql

cmd "rm -f ${DATADIR}/galera.cache ${DATADIR}/grastate.dat ${DATADIR}/gvwstate.dat"

#info "REMOVE CONF WSREP"
#grep -ER 'wsrep_' * | cut -d: -f1| sort |uniq |xargs -n1 perl -i -pe 's/^wsrep_/#wsrep_/g'

# Reverse operation
#grep -ER '#wsrep_' * | cut -d: -f1| sort |uniq |xargs -n1 perl -i -pe 's/^#wsrep_/wsrep_/g'

cmd "systemctl start mariadb"

footer "END SCRIPT: $NAME"
exit $lRC
