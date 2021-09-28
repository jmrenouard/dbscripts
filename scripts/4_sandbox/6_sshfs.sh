#!/bin/bash

lRC=0

default_mode=rw

setup_ubuntu_sshfs_server()
{
    apt update
    apt -y install sshfs
}

setup_ubuntu_sshfs_client()
{
    apt update
    apt -y install sshfs
}

setup_centos_sshfs_client()
{
    yum -y install sshfs
}

createSSHfsShare()
{
    local mp=$1
    shift
    mkdir -p $mp
    chmod 777 $mp
    chown nobody:nogroup $mp

    sed -i "/$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/exports
    for ip in $*; do
                   echo "$mp $ip(${default_mode},sync,no_subtree_check)" >> /etc/exports
    done
    exportfs -rav
    systemctl restart nfs-kernel-server
}

removeSSHfsShare()
{
    local mp=$1
    sed -i "/$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/exports
    exportfs -rav
    systemctl restart nfs-kernel-server
}

mountSSHfsShare()
{
    srv=$1
    mp=$2
    lmp=$3

    [ -d "$lmp" ] || mkdir -p $lmp

    sed -i "/${srv}:$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/fstab

    df -Ph | grep "$lmp"
    [ $? -eq 0 ] && umount $lmp

    mount $lmp

    if [ $? -eq 0 ]; then
                   echo "$srv:$mp    $lmp   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab
    fi
    df -Ph
}

umountSSHfsShare()
{
    lmp=$1

    sed -i "/$(echo $lmp| perl -pe 's/\//\\\//g')/d" /etc/fstab

    df -Ph | grep "$lmp"
    [ $? -eq 0 ] && umount $lmp

    df -Ph
}

setup_ubuntu_sshfs_client