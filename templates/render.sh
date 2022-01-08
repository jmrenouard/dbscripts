#!/bin/bash

tmpInventory=$(mktemp)

echo "[local]
localhost ansible_host=127.0.0.1 ansible_connection=local">$tmpInventory

tplName=$1
tplVarFile=$2
tplOutput=$3
renderStdout=0

if [ ! -f "$tplName" ];then
	echo "template $tplName doesnt exist"
	exit 1
fi

if [ ! -f "$tplName" ];then
	echo "template $tplName doesnt exist"
	exit 1
fi

if [ -z "$tplOutput" ];then
	tplOutput=$(mktemp)
	ansible all -e"@$tplVarFile" -i $tmpInventory -mtemplate -a "src=$tplName dest=$tplOutput" &>/dev/null 
	if [ $? -eq 0 ]; then
		cat $tplOutput
		rm -f $tplOutput $tmpInventory
		exit 0
	fi
	exit 2
fi
ansible all -e"@$tplVarFile" -i $tmpInventory -mtemplate -a "src=$tplName dest=$tplOutput"
rm -f  $tmpInventory
