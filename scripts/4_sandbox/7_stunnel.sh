#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

#!/bin/bash
default_mode=rw

setup_ubuntu_stunnel_server()
{
    apt update
    apt -y install nfs-kernel-server nfswatch nfstrace quota stunnel4
}

setup_ubuntu_stunnel_client()
{
    apt update
    apt -y install nfs-common stunnel4
}

setup_centos_stunnel_client()
{
    yum -y install epel-release
    yum -y install nfs-utils stunnel
}

create_stunnel_config()
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

removestunnelShare()
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

    mount $lmp

    if [ $? -eq 0 ]; then
                   echo "$srv:$mp    $lmp   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab
    fi
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
