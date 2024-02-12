#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh
[ -f "$(pwd)/utils.sh" ] && source "$(pwd)/utils.sh"


lRC=0

#!/bin/bash
default_mode=rw

setup_ubuntu_nfs_server()
{
    apt -y install nfs-kernel-server nfswatch nfstrace quota
}

setup_ubuntu_nfs_client()
{
    apt -y install nfs-common
}

setup_centos_nfs_client()
{
    yum -y install nfs-utils
}

createNfsShare()
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

removeNfsShare()
{
    local mp=$1
    sed -i "/$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/exports
    exportfs -rav
    systemctl restart nfs-kernel-server
}

mountNfsShare()
{
    srv=$1
    mp=$2
    lmp=$3

    [ -d "$lmp" ] || mkdir -p $lmp

    sed -i "/${srv}:$(echo $mp| perl -pe 's/\//\\\//g')/d" /etc/fstab

    df -Ph | grep "$lmp"
    [ $? -eq 0 ] && umount $lmp

    echo "$srv:$mp    $lmp   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab

    mount $lmp
    df -Ph
}

umountNfsShare()
{
    lmp=$1

    sed -i "/$(echo $lmp| perl -pe 's/\//\\\//g')/d" /etc/fstab

    df -Ph | grep "$lmp"
    [ $? -eq 0 ] && umount $lmp

    df -Ph
}
