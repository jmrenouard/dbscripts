#!/bin/bash

SLEEP_TIME=${1:-"2s"}
SLEEP_RETRY=${2:-"5"}

is_slave=$(mysql -Nrs -e 'Show Slave Status\G'| wc -l)

[ "$is_slave" = "0" ] && exit 0

SLAVE_IO=""
SLAVE_SQL=""

i=$SLEEP_RETRY
while [  "${SLAVE_IO}" != "Yes" -o "${SLAVE_SQL}" != "Yes" ]; do
	sleep $SLEEP_TIME  
	SLAVE_IO=$(mysql -e 'SHOW SLAVE STATUS\G' | grep Slave_IO_Running:  | awk {'print $2'}| xargs)
	SLAVE_SQL=$(mysql -e 'SHOW SLAVE STATUS\G' | grep Slave_SQL_Running:  | awk {'print $2'}|xargs)
	echo " IO: ($SLAVE_IO) SQL: ($SLAVE_SQL)"
        i=$(($i - 1))
        [ $i -le 0 ] && break
done

if [ $i -le 0 ]; then
	echo " IO: $SLAVE_IO SQL: $SLAVE_SQL"
	echo "Slave not connected"
	exit 127
fi

lag_cmd=$(mysql -rs -e 'Show Slave Status\G'| grep 'Seconds_Behind_Master'| cut -d: -f2| xargs)
i=$SLEEP_RETRY
while [ "$lag_cmd" != "0" -a "$lag_cmd" != "NULL" -a -n "$lag_cmd" ]; do
        sleep $SLEEP_TIME
        echo "Sleep ${SLEEP_TIME} ... ok"
        i=$(($i - 1))
        [ $i -le 0 ] && break
        lag_cmd=$(mysql -rs -e 'Show Slave Status\G'| grep 'Seconds_Behind_Master'| cut -d: -f2| xargs)
done

lag_cmd=$(mysql -rs -e 'Show Slave Status\G'| grep 'Seconds_Behind_Master'| cut -d: -f2| xargs)
lRC=$lag_cmd
[ -z "$lRC" -o "$lRC" = "NULL" ] && lRC=0
exit $lRC

