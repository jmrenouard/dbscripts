#!/bin/bash

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
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


bench_fs()
{
OUT=${1:-"/var/tmp"}
REP=${2:-"/backups"}
fio --name=job-w --rw=write --size=2G --ioengine=libaio --iodepth=4 --bs=128k --direct=1 --filename=$REP/bench.file --output-format=normal,terse --output=$OUT/fio-write.log
sleep 5
fio --name=job-r --rw=read --size=2G --ioengine=libaio --iodepth=4 --bs=128K --direct=1 --filename=$REP/bench.file --output-format=normal,terse --output=$OUT/fio-read.log
sleep 5
fio --name=job-randw --rw=randwrite --size=2G --ioengine=libaio --iodepth=32 --bs=4k --direct=1 --filename=$REP/bench.file --output-format=normal,terse --output=$OUT/fio-randwrite.log
sleep 5
fio --name=job-randr --rw=randread --size=2G --ioengine=libaio --iodepth=32 --bs=4K --direct=1 --filename=$REP/bench.file --output-format=normal,terse --output=$OUT/fio-randread.log
echo "terse_version;fio_version;jobname;groupid;error;READ_kb;READ_bandwidth;READ_IOPS;READ_runtime;READ_Slat_min;READ_Slat_max;READ_Slat_mean;READ_Slat_dev;READ_Clat_max;READ_Clat_min;READ_Clat_mean;READ_Clat_dev;READ_clat_pct01;READ_clat_pct02;READ_clat_pct03;READ_clat_pct04;READ_clat_pct05;READ_clat_pct06;READ_clat_pct07;READ_clat_pct08;READ_clat_pct09;READ_clat_pct10;READ_clat_pct11;READ_clat_pct12;READ_clat_pct13;READ_clat_pct14;READ_clat_pct15;READ_clat_pct16;READ_clat_pct17;READ_clat_pct18;READ_clat_pct19;READ_clat_pct20;READ_tlat_min;READ_lat_max;READ_lat_mean;READ_lat_dev;READ_bw_min;READ_bw_max;READ_bw_agg_pct;READ_bw_mean;READ_bw_dev;WRITE_kb;WRITE_bandwidth;WRITE_IOPS;WRITE_runtime;WRITE_Slat_min;WRITE_Slat_max;WRITE_Slat_mean;WRITE_Slat_dev;WRITE_Clat_max;WRITE_Clat_min;WRITE_Clat_mean;WRITE_Clat_dev;WRITE_clat_pct01;WRITE_clat_pct02;WRITE_clat_pct03;WRITE_clat_pct04;WRITE_clat_pct05;WRITE_clat_pct06;WRITE_clat_pct07;WRITE_clat_pct08;WRITE_clat_pct09;WRITE_clat_pct10;WRITE_clat_pct11;WRITE_clat_pct12;WRITE_clat_pct13;WRITE_clat_pct14;WRITE_clat_pct15;WRITE_clat_pct16;WRITE_clat_pct17;WRITE_clat_pct18;WRITE_clat_pct19;WRITE_clat_pct20;WRITE_tlat_min;WRITE_lat_max;WRITE_lat_mean;WRITE_lat_dev;WRITE_bw_min;WRITE_bw_max;WRITE_bw_agg_pct;WRITE_bw_mean;WRITE_bw_dev;CPU_user;CPU_sys;CPU_csw;CPU_mjf;PU_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops;disk_read_merges;disk_write_merges;disk_read_ticks;write_ticks;disk_queue_time;disk_utilization"
}
# If run directly as a script (optional, as this is mostly a library)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    banner "BEGIN SCRIPT: ${_NAME}"
    info "This script contains functions for sshfs setup and benchmark."
    info "No default action is performed when run directly."
    footer "END SCRIPT: ${_NAME}"
fi
exit $lRC
