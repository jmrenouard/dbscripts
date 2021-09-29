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
    yum -y install epel-release
    yum -y install fuse-sshfs
}

create_sshfs_share()
{
    local mp=$1
    shift

    # création du répertoire uniquement
    mkdir -p $mp
    chmod 777 $mp
    chown nobody:nogroup $mp

    [ -d "/home/backupbdd" ] ||adduser --disabled-password --gecos ""  backupbdd


    #sed -i "/$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/exports
    #for ip in $*; do
    #               echo "$mp $ip(${default_mode},sync,no_subtree_check)" >> /etc/exports
    #done
    #exportfs -rav
    #systemctl restart nfs-kernel-server
}

remove_sshfs_share()
{
    local mp=$1
    truelcop
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

#setup_ubuntu_sshfs_server
#setup_ubuntu_sshfs_client
#setup_centos_sshfs_client

