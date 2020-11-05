#!/bin/bash
VAGRANT=$(which vagrant 2>/dev/null)
[ -z "$VAGRANT" ] && VAGRANT=$(which vagrant.exe)
$VAGRANT ssh-config $*
$VAGRANT status $*

for vm in $($VAGRANT status| grep running|awk '{print $1}'); do
echo -e "------------------------\n$vm\n----------------"
echo "PING:"
ping -c1 $vm
echo "--------------------------"
ssh root@$vm -i id_rsa "echo -n hostname: ;hostname -s;\
echo 'LISTE IPS:'
ip a| grep inet | grep -v 127.0.0.1 | grep -v inet6 | grep -v 10.0.2.15 |cut -d/ -f 1\

echo 'CONTENU /etc/hosts:'
cat /etc/hosts"
echo "#######################"
done

