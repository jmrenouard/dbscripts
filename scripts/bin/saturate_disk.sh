#!/bin/sh

mp=$1
freeEnd=${2:-"100"}

if [ "$freeEnd" = "rm" ]; then
  rm -f ${mp}/dd.file
  exit $?
fi

available=$(df -P| grep $mp | awk '{print $4}')
sizedd=$(($available-$freeEnd))

dd bs=1024 if=/dev/zero of=${mp}/dd.file count=$sizedd

