#!/bin/bash
### BEGIN INIT INFO
# Provides:          tc
# Required-Start:    $syslog $network $remote_fs
# Required-Stop:     $syslog $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Bandwidth Shaping
# Description:       Bandwidth Shaping
### END INIT INFO
#  tc uses the following units when passed as a parameter.
#  kbps: Kilobytes per second 
#  mbps: Megabytes per second
#  kbit: Kilobits per second
#  mbit: Megabits per second
#  bps: Bytes per second 
#       Amounts of data can be specified in:
#       kb or k: Kilobytes
#       mb or m: Megabytes
#       mbit: Megabits
#       kbit: Kilobits
#
 
#
# Name of the traffic control command.
TC=/sbin/tc
 
# The network interface we're planning on limiting bandwidth.
IF=eth0             # Interface
 
# Download limit (in mega bits)
DNLD=10mbit          # DOWNLOAD Limit
 
# Upload limit (in mega bits)
UPLD=10mbit          # UPLOAD Limit
 
# Burst limit
BURST=2mbit
 
# IP address of the machine we are controlling
IP=10.0.1.1     # Host IP
 
# Filter options for limiting the intended interface.
U32="$TC filter add dev $IF protocol ip parent 1:0 prio 1 u32"
 
start() {
    $TC qdisc add dev $IF root handle 1: htb default 30
    $TC class add dev $IF parent 1: classid 1:1 htb rate $DNLD burst $BURST cburst $BURST
    $TC class add dev $IF parent 1: classid 1:2 htb rate $UPLD burst $BURST cburst $BURST
    $U32 match ip dst $IP/32 flowid 1:1
    $U32 match ip src $IP/32 flowid 1:2
}
 
stop() {
    $TC qdisc del dev $IF root
}
 
restart() {
    stop
    sleep 1
    start
}
 
show() {
    $TC -s qdisc ls dev $IF
    echo ""
    $TC -s class show dev $IF
}
 
showfilter() {
    $TC -s filter show dev $IF
}
 
case "$1" in
 
  start)
    echo -n "Starting bandwidth shaping: "
    start
    echo "done"
    ;;
 
  stop)
    echo -n "Stopping bandwidth shaping: "
    stop
    echo "done"
    ;;
 
  restart)
    echo -n "Restarting bandwidth shaping: "
    restart
    echo "done"
    ;;
 
  show)
    echo "Bandwidth shaping status for $IF:"
    show
    echo ""
    ;;
 
  showfilter)
    echo "Filter shaping status for $IF:"
    showfilter
    echo ""
    ;;
 
  *)
    pwd=$(pwd)
    echo "Usage: ./tc {start|stop|restart|show|showfilter}"
    ;;
 
esac
 
exit 0
