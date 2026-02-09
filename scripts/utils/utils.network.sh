#!/bin/bash
# utils.network.sh - Network utilities for dbscripts

export my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)
export my_public_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)

SSH_CLIENT="ssh -q -o TCPKeepAlive=yes -o ServerAliveInterval=50 -o strictHostKeyChecking=no"
SCP_CLIENT="scp -q -o TCPKeepAlive=yes -o ServerAliveInterval=50 -o strictHostKeyChecking=no"

ha_status()
{
    local param=${1:-"info"}
    echo "show $param" |  socat unix-connect:$HA_SOCKET stdio
}
ha_states()
{
   (echo -e "NAME TYPE STATE"
    echo "show stat" |  socat unix-connect:$HA_SOCKET stdio| cut -d, -f1,2,18 | tr ',' '\t'| sort -k 3| grep -ve '^#'
    )|column -t
}
ha_disable()
{
    echo "disable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}
ha_enable()
{
    echo "enable server ${1:-"galera/node1"}" |  socat unix-connect:$HA_SOCKET stdio
}

ssh_exec()
{
    local lsrv=$1
    local lRC=0
    shift

    for fcmd in $*; do
        if [ ! -f "$fcmd" ]; then
            error "$fcmd Not exists"
            return 127
        fi
        INTERPRETER=$(head -n 1 $fcmd | sed -e 's/#!//')

        for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
            title2 "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            (echo "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh";echo;cat $fcmd) | grep -v "#!" | ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} $INTERPRETER
            footer "RUNNING SCRIPT $(basename $fcmd) ON $srv SERVER"
            lRC=$(($lRC + $?))
        done
    done
    return $lRC
}

ssh_cmd()
{
    local lsrv=$1
    local lRC=0
    local fcmd=$2
    local silent=$3

    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        [ -z "$silent" ] && title2 "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
        [ -n "$silent" ] && echo -ne "$srv\t$fcmd\t"
        ssh -T root@$srv -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"} "$fcmd"
        lRC=$(($lRC + $?))
        [ -n "$silent" ] && echo
        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv($vip) SERVER"
    done
    return $lRC
}

ssh_copy()
{
    local lsrv=$1
    local fsource=$2
    local fdest=$3
    local own=$4
    local mode=$5
    local lRC=0

    if [ ! -f "$fsource" -a ! -d "$fsource" ]; then
        error "$fsource Not exists"
        return 127
    fi
    for srv in $(echo $lsrv | perl -pe 's/[, :]/\n/g'); do
        rsync -avz  -e "ssh -i ${DEFAULT_PRIVATE_KEY:-"/root/.ssh/id_rsa"}" $fsource root@$srv:$fdest
        lRC=$(($lRC + $?))

        [ -z "$own" ] || ssh_cmd $srv "chown -R $own:$own $fdest" silent
        lRC=$(($lRC + $?))
        [ -z "$mode" ] || ssh_cmd $srv "chmod -R $mode $fdest" silent
        lRC=$(($lRC + $?))

        [ -z "$silent" ] && footer "RUNNING SCRIPT $fcmd ON $srv SERVER"
        lRC=$(($lRC + $?))
    done
    return $lRC
}

test_ping()
{
    #source ansible/source
    for srv in $(list_svg_srv); do
        ping -c2 -W4 $srv &>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
        fi
        [ "$1" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

test_tcp_port()
{
    #source ansible/source
    for srv in $(list_svg_srv); do
        nc -w3 $srv $1 &>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

test_remote_tcp_port()
{
    #source ansible/source
    tgt=backup.vm.local
    port=${1:-"111"}
    for srv in $(list_svg_srv); do
        ssh -q $srv "hostname;nc -v -w1 $tgt $1" #&>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
            continue
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}

test_remote_udp_port()
{
    #source ansible/source
    tgt=backup.vm.local
    port=${1:-"111"}
    for srv in $(list_svg_srv); do
        ssh $srv "nc -vv -u -w3 $tgt $1" #&>/dev/null

        if [ $? -ne 0 ];then
            echo -e "$srv\t[FAIL]"
            continue
        fi
        [ "$2" == "quiet" ] && echo -e "$srv\t[ OK ]"
    done
}
