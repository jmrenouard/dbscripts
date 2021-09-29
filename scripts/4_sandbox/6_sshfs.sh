#!/bin/bash

lRC=0

default_mode=rw

# install functions
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


# Functions for SERVER only
create_sshfs_share()
{
    local mp=${1:-"backups"}
    local default_mode=${2:-"rw"}
    shift

    [ -d "/home/backupbdd" ] ||adduser --disabled-password --gecos ""  backupbdd

    [ -d "/etc/backupbdd" ] || mkdir -p /etc/backupbdd
    chmod 640 /etc/backupbdd
    [ -f "/etc/backupbdd/id_rsa_backupbdd" ] ||  ssh-keygen -t rsa -N "" -C "SSH keys For Database Backup" -f /etc/backupbdd/id_rsa_backupbdd

    if [ ! -d "/home/backupbdd/.ssh" ];then
        mkdir -p /home/backupbdd/.ssh
        cat /etc/backupbdd/id_rsa_backupbdd.pub >> /home/backupbdd/.ssh/authorized_keys
        chown  -R backupbdd. /home/backupbdd/.ssh
        chmod 600 /home/backupbdd/.ssh/authorized_keys
    fi


    if [ ! -d "/$mp" ]; then
        mkdir -p /$mp
    fi

    if [ "$default_mode" = "rw" ]; then
        chown  -R backupbdd. /$mp
    else
        chown  -R root. /$mp
    fi

    ls -ls /${mp}
    ls -lsh /${mp} | grep $mp
}

push_backup_ssh_config()
{
    local target=$1
    rsync -avz /etc/backupbdd $target:/etc

    mkdir -p /backups/$target
    chown -R backupbdd. /backups/$target
}


create_sshfs_share_backups()
{
    create_sshfs_share backups rw
}

create_sshfs_share_share()
{
    create_sshfs_share share ro
}

# functions for Client only
mount_sshfs_client()
{
    local mp=${1:-"backups"}
    local mode=${2:-"rw"}
    local server=${3:-"176.58.120.128"}

    local remote_mp=/${mp}

    if [ "backups" = "${mp}" ]; then
        remote_mp="/${mp}/$(hostname -s)"
        ssh -i /etc/backupbdd/id_rsa_backupbdd backupbdd@${server} "mkdir -p $remote_mp"
    fi
    local systemd_conf="/lib/systemd/system/${mp}.mount"
    cd /tmp

    df -Ph | grep -q /${mp}
    [ $? -eq 0 ] && umount /${mp}

    [ -d "/${mp}" ] || mkdir -p /${mp}
    if [ -f "$systemd_conf" ]; then
        systemctl stop ${mp}.mount
        systemctl disable ${mp}.mount
    fi
#    rm -f $systemd_conf
    echo "[Unit]
Description=Mount remote fs with sshfs for $mp

[Install]
WantedBy=multi-user.target

[Mount]
What=backupbdd@${server}:${remote_mp}
Where=/${mp}
Type=fuse.sshfs
Options=_netdev,allow_other,IdentityFile=/etc/backupbdd/id_rsa_backupbdd,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount,uid=0,gid=0,$mode
TimeoutSec=60
" > $systemd_conf
    systemctl daemon-reload
    systemctl enable ${mp}.mount
    systemctl start ${mp}.mount

    df -hP
    systemctl status ${mp}.mount
}

umount_sshfs_client()
{
    local mp=${1:-"backups"}
    cd /tmp
    local systemd_conf="/lib/systemd/system/${mp}.mount"

    umount /${mp}
    if [ -f "$systemd_conf" ]; then
        systemctl stop ${mp}.mount
        systemctl disable ${mp}.mount
        systemctl daemon-reload
    fi
    rm -f $systemd_conf
    rm -fr /${mp}
    systemctl daemon-reload
    df -Ph
}

mount_sshfs_share_share()
{
    mount_sshfs_client share ro
}

mount_sshfs_share_backups()
{
    mount_sshfs_client backups rw
}

umount_sshfs_share_share()
{
    umount_sshfs_client share
}

umount_sshfs_share_backup()
{
    umount_sshfs_client backups
}
