#!/bin/bash
[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f '/etc/bootstrap.conf' ] && source /etc/bootstrap.conf


title2 "FLUSHING BINARY LOGS"
mysql -v -e "FLUSH BINARY LOGS;"


title2 "GETTING LAST BINLOG FILE"
last_binlog=$(mysql -Nrs  -e'show binary logs' | sort -nr| head -n 1 | awk '{print $1}')
info "Last binlog: $last_binlog"

title2 "REMOVING ALL PREVIOUS BIN LOG"

mysql -v  -e " PURGE BINARY LOGS TO '$last_binlog'" 

title2 "CURRENT BINARY LOG"
mysql -e 'show binary logs'