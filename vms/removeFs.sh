#!/bin/sh

vmssh()
{
	local vm=$1
	shift
 	ssh -i ./id_rsa root@$vm $@
}

vmssh $1 umount /data
vmssh $1 pvremove /dev/datavol/data 
vmssh $1 df -Ph
vmssh $1 vgremove datavol

