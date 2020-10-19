#!/bin/bash

while [ $# -gt 0 ]
do
   case $1 in
      --status)
         STATUS=$2
         shift
         ;;
      --uuid)
         CLUSTER_UUID=$2
         shift
         ;;
      --primary)
         [ "$2" = "yes" ] && PRIMARY="1" || PRIMARY="0"
         COM=configuration_change
         shift
         ;;
      --index)
         INDEX=$2
         shift
         ;;
      --members)
         MEMBERS=$2
         shift
         ;;
         esac
         shift
   done

# Undefined means node is shutting down
touch /tmp/galera.notif.txt
if [ "$(whoami)" = "root" ]; then
   chmod 700 /tmp/galera.notif.txt
   chown mysql. /tmp/galera.notif.txt

echo -e "$(date)\t$(hostname -s)\t$INDEX\t$STATUS\t$CLUSTER_UUID\t$PRIMARY\t$MEMBERS" >> /tmp/galera.notif.txt
exit 0
