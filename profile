#!/bin/sh

if [ "$0" != "/bin/bash" -a "$0" != "-bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
else
	_DIR="$(readlink -f ".")"
fi
[ "$(pwd)" = "$HOME" ] && export _DIR="$HOME/dbscripts/"

export VMS_DIR="$(readlink -f ".")/vms"
[ -d "${_DIR}/../vms" ] && export VMS_DIR="${_DIR}/../vms"
[ -d "${_DIR}/vms" ] && export VMS_DIR="${_DIR}/vms"
[ -z "$DEFAULT_PRIVATE_KEY" ] && export DEFAULT_PRIVATE_KEY="$HOME/.ssh/id_rsa"

export proxy_vms="proxy1,proxy2"
export db_vms="dbsrv1,dbsrv2,dbsrv3"
export app_vms="app1"
export all_vms="app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"

is() {
    if [ "$1" == "--help" ]; then
        cat << EOF
Conditions:
  is equal VALUE_A VALUE_B
  is matching REGEXP VALUE
  is substring VALUE_A VALUE_B
  is empty VALUE
  is number VALUE
  is gt NUMBER_A NUMBER_B
  is lt NUMBER_A NUMBER_B
  is ge NUMBER_A NUMBER_B
  is le NUMBER_A NUMBER_B
  is file PATH
  is dir PATH
  is link PATH
  is existing PATH
  is readable PATH
  is writeable PATH
  is executable PATH
  is available COMMAND
  is older PATH_A PATH_B
  is newer PATH_A PATH_B
  is true VALUE
  is false VALUE
  is fowner PATH USER
  is fgroup  PATH GROUP
  is fmountpoint PATH MOUNTPOINT
  is fempty PATH
  is fsize PATH BYTE_SIZE
  is fsizelt PATH$path BYTE_SIZE
  is fsizegt PATH$path BYTE_SIZE
  is forights PATH OCTALRIGHTS
  is fuser USER
  is tcp_port PORTNUMBER

Negation:
  is not equal VALUE_A VALUE_B

Optional article:
  is not a number VALUE
  is an existing PATH
  is the file PATH
EOF
        exit
    fi

    if [ "$1" == "--version" ]; then
        echo "is.sh 1.1.0"
        exit
    fi

    local condition="$1"
    local value_a="$2"
    local value_b="$3"

    if [ "$condition" == "not" ]; then
        shift 1
        ! is "${@}"
        return $?
    fi

    if [ "$condition" == "a" ] || [ "$condition" == "an" ] || [ "$condition" == "the" ]; then
        shift 1
        is "${@}"
        return $?
    fi

    case "$condition" in
        file)
            [ -f "$value_a" ]; return $?;;
        dir|directory)
            [ -d "$value_a" ]; return $?;;
        link|symlink)
            [ -L "$value_a" ]; return $?;;
        existent|existing|exist|exists)
            [ -e "$value_a" ]; return $?;;
        readable)
            [ -r "$value_a" ]; return $?;;
        writeable)
            [ -w "$value_a" ]; return $?;;
        executable)
            [ -x "$value_a" ]; return $?;;
        available|installed)
            which "$value_a"; return $?;;
        tcp_port_open|tcp_port|tport)
            netstat -ltn | grep -E ":${value_a}\s" | grep -q 'LISTEN'; return $?;;
        fowner|fuser)
            [ "$(stat -c %U $value_a)" = "$value_b" ]; return $?;;
        fgroup)
            [ "$(stat -c %G $value_a)" = "$value_b" ]; return $?;;
        fmountpoint)
            [ "$(stat -c %m $value_a)" = "$value_b" ]; return $?;;
        fempty)
            [ "$(stat -c %s $value_a)" = "0" ]; return $?;;
        fsize)
            [ $(stat -c %s $value_a) -eq $value_b ]; return $?;;
        fsizelt)
            [ $(stat -c %s $value_a) -lt $value_b ]; return $?;;
        fsizegt)
            [ $(stat -c %s $value_a) -gt $value_b ]; return $?;;
        forights)
            [ "$(stat -c %a $value_a)" = "$value_b" ]; return $?;;
        fagegt)
			[ $(fileAge $value_a) -gt $value_b ]; return  $?;;
        fagelt)
			[ $(fileAge $value_a) -lt $value_b ]; return  $?;;
        fmagegt)
			[ $(fileMinAge $value_a) -gt $value_b ]; return  $?;;
        fmagelt)
			[ $(fileMinAge $value_a) -lt $value_b ]; return  $?;;
        fhagegt)
			[ $(fileHourAge $value_a) -gt $value_b ]; return  $?;;
        fhagelt)
			[ $(fileHourAge $value_a) -lt $value_b ]; return  $?;;
        fdagegt)
			[ $(fileDayAge $value_a) -gt $value_b ]; return  $?;;
        fdagelt)
			[ $(fileDayAge $value_a) -lt $value_b ]; return  $?;;
        fcontains)
			shift;
			grep -q "$*" $value_a
			return  $?
			;;
        user)
            is eq $(whoami) $value_a; return $?;;
        empty)
            [ -z "$value_a" ]; return $?;;
        number)
            echo "$value_a" | grep -E '^[0-9]+(\.[0-9]+)?$'; return $?;;
        older)
            [ "$value_a" -ot "$value_b" ]; return $?;;
        newer)
            [ "$value_a" -nt "$value_b" ]; return $?;;
        gt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a > $value_b ? 0 : 1}"; return $?;;
        lt)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a < $value_b ? 0 : 1}"; return $?;;
        ge)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a >= $value_b ? 0 : 1}"; return $?;;
        le)
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a <= $value_b ? 0 : 1}"; return $?;;
        eq|equal)
            [ "$value_a" = "$value_b" ]     && return 0;
            is not a number "$value_a"      && return 1;
            is not a number "$value_b"      && return 1;
            awk "BEGIN {exit $value_a == $value_b ? 0 : 1}"; return $?;;
        match|matching)
            echo "$value_b" | grep -xE "$value_a"; return $?;;
        substr|substring)
            echo "$value_b" | grep -F "$value_a"; return $?;;
        true)
            [ "$value_a" == true ] || [ "$value_a" == 0 ]; return $?;;
        false)
            [ "$value_a" != true ] && [ "$value_a" != 0 ]; return $?;;
    esac > /dev/null

    return 1
}
sanitize_md()
{
    sed -r -i "s/\x1B\[([0-9];)?([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g;s/\[0(;33|33|;32|)m//g"  $*
}


now() {
    # echo "$(date "+%F %T %Z")"
    echo "$(date "+%F %T %Z")($(hostname -s))"
}

error() {
    local lRC=$?
    echo "$(now) ERROR: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) ERROR: $*">>$TEE_LOG_FILE
    return $lRC
}

die() {
    error $*
    exit 1
}

info() {
    [ "$quiet" != "yes" ] && echo "$(now) INFO: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) INFO: $*">>$TEE_LOG_FILE
    return 0
}

ok()
{
    info "$* [SUCCESS]"
    return $?
}

warn() {
	local lRC=$?
    echo "$(now) WARNING: $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) WARNING: $*">>$TEE_LOG_FILE
    return $lRC
}

warning()
{
    warn "$*"
}
sep1()
{
    echo "$(now) -----------------------------------------------------------------------------" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) -----------------------------------------------------------------------------" >>$TEE_LOG_FILE
}
sep2()
{
    echo "$(now) _____________________________________________________________________________" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) _____________________________________________________________________________" >>$TEE_LOG_FILE
}
title1() {
    sep1
	echo "$(now) $*" 1>&2
	[ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
	sep1
}

title2()
{
    echo "$(now) $*" 1>&2
    [ -n "$TEE_LOG_FILE" ] && echo "$(now) $*">>$TEE_LOG_FILE
    sep2
}
banner()
{
	title1 "START: $*"
}

footer()
{
    local lRC=${lRC:-"$?"}

    [ $lRC -eq 0 ] && title1 "END: $* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || title1 "END: $* ENDED WITH WARNING OR ERROR ($lRC)"
    return $lRC
}

pgGetVal()
{
	local value=$1
	echo $(eval "echo \$${value}")
}

pgSetVal()
{
	local var=$1
	shift
	eval "${var}='$*'"
}


##
# cpall mariadb.repo  /etc/yum.repos.d
# execall "yum -y install MariaDB-server MariaDB-client"
# execall "systemctl start mariadb"
# execall "systemctl status mariadb"


# execall "iptables --flush;iptables -L"
# execall "setenforce 0;sestatus"

# execall "yum -y install socat MariaDB-backup rsync lsof percona-toolkit mysql-utilities"
# execall "yum -y install ntpdate"
# execall "ntpdate -vqd fr.pool.ntp.org"

# 919  cpall changeIdserver.sh /tmp
#  920  execall "cat /etc/my.cnf.d/60_server.cnf"
#  921  execall "sh /tmp/changeIdserver.sh"
#  922  execall "cat /etc/my.cnf.d/60_server.cnf"
#  923  execall "systemctl restart mariadb"

# execall "setenforce  0"
# execall "cat /tmp/security.sql | mysql"
# cpall 61_galera.cnf  /etc/my.cnf.d/
# cpall changeWsrepConfig.sh /tmp
# execall "sh /tmp/changeWsrepConfig.sh"


alias sssh='sudo ssh -l root'
alias rsh='ssh -l root'
alias srsync="sudo rsync  -e 'ssh -l root'"
alias pass='pwgen -1 18'

alias s=sudo
alias sssh='sudo ssh -l root'
alias srsync="sudo rsync  -e 'ssh -l root'"

alias gst="git status"
alias ga="git add"
alias gam="git status | grep modified: | cut -d: -f2 | xargs -n 1 git add"
alias gad="git status | grep deleted:  | cut -d: -f2 | xargs -n1 git rm -f"

greset()
{
	git fetch --all
	git reset --hard origin/master
	git pull
}

alias h=history
rl()
{
	cd ${_DIR}
	source ${_DIR}/profile
}

# ansible
export ANSIBLE_LOAD_CALLBACK_PLUGINS=1
export ANSIBLE_STDOUT_CALLBACK="minimal"
export ANSIBLE_EXTRA_OPTIONS=""
export ANSIBLE_INVENTORY=${_DIR}/inventory
export ANSIBLE_CONFIG=${_DIR}/.ansible.cfg

alias an="time ansible -f $(nproc)"
alias anh="time ansible --list-hosts"
alias anv="time ansible -f $(nproc) -v"
alias and="time ansible -f $(nproc) -v --step"

# Alias pour ansible-playbook
alias ap="time ansible-playbook -f $(nproc)"
alias apv="time ansible-playbook -f $(nproc) --verbose"
alias apd="time ansible-playbook -f $(nproc) --verbose --step"

# Alias pour le debugging des playbooks et roles
alias apchk="time ansible-playbook --syntax-check"
alias aphst="time ansible-playbook --list-hosts"
alias aptsk="time ansible-playbook --list-tasks"

alias anl="time ansible-lint"

ff()
{
find . -iname "$1"
}

yamlval()
{
        time python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))' < $1
}

ltrim()
{
        perl -i -pe 's/[\t ]+$//g' $1
}


randpw()
{
        if [ ! -f "/usr/bin/pwgen" ]; then
                echo "yum -y install pwgen"
                return 1
        fi
        pwgen -c -n  -y -s -v  12 1
        return $?
}

alias | grep -q gcm && unalias gcm
gcm()
{
        git commit -m "$@"
}


asetdebug()
{
	export ANSIBLE_STDOUT_CALLBACK="debug"
	export ANSIBLE_EXTRA_OPTIONS="--verbose"
}

asetoneline()
{
	export ANSIBLE_STDOUT_CALLBACK="oneline"
	export ANSIBLE_EXTRA_OPTIONS=""
}

asetquiet()
{
	export ANSIBLE_STDOUT_CALLBACK="dense"
	export ANSIBLE_EXTRA_OPTIONS=""
}
asetnormal()
{
	export ANSIBLE_STDOUT_CALLBACK="minimal"
	export ANSIBLE_EXTRA_OPTIONS=""
}


acp()
{
    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $1 -mcopy -a "src=$2 dest=$3"

    if [ -n "$4" ]; then
        acmd $1 "chown -R $4.$4 $3"
    fi
    if [ -n "$5" ]; then
        acmd $1 "chmod -R $5 $3"
    fi
}

aexec()
{
    local target=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $target -mscript -a "$*"
}

auexec()
{
    local target=$1
    shift
    local user=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $target -mscript -b --become-user=$user -a "$*"
}

acmd()
{
    local target=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $target -mshell -a "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh;$*"
}

aucmd()
{
    local target=$1
    shift
    local user=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"debug"}
    echo "stdout_calback: $ANSIBLE_STDOUT_CALLBACK"
    ansible -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $target -mshell -b --become-user=$user -a "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh;$*"
}


synchronize_dir()
{
	local src_host=$1
	local src_rep=$2
	local dest_host=$3
	local dest_rep=${4:-"$2"}
	local src_user=root
	local dest_user=root

	echo "* Copie $src_host:$src_rep => $dest_host:$dest_rep"
	date
	ssh ${src_user}@${src_host} "cd ${src_rep};tar -cvzf - ." | ssh ${dest_user}@${dest_host} "mkdir -p ${dest_rep};cd ${dest_rep};tar -xvzf -"
	date
	ssh ${dest_user}@${dest_host} chown -R postgres. $dest_rep
}

#echo "synchronize_dir alipgflif01 /backups/export_07082019 alipgslir05 /backups/test_07082019"

##############################################################################################################
# ANSIBLE CODE
##############################################################################################################
genAnsibleCfg()
{
	local pkey=${1:-"$HOME/.conf/id_rsa"}
	local ctrlm=${2:-"auto"}

	[ "$pkey" = "-" ] && pkey="$HOME/.conf/id_rsa"


	[ -f "$HOME/id_rsa" -a "$pkey" != "$HOME/id_rsa" ] && rm -f $HOME/id_rsa
	if [ ! -f "$HOME/id_rsa" -a "$pkey" = "$HOME/id_rsa" ]; then
		cp $VMS_DIR/id_rsa $HOME
		chmod 600 $HOME/id_rsa
	fi

	echo "[defaults]
system_warnings=False
command_warnings=False
remote_user=root
private_key_file=$pkey
inventory =${_DIR}/inventory
bin_ansible_callbacks=True
[ssh_connection]
ssh_args = -o ControlMaster=$ctrlm -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no"
scp_if_ssh=True" > $ANSIBLE_CONFIG

	echo "Fichier de config: $ANSIBLE_CONFIG"
	cat $ANSIBLE_CONFIG
}

genAnsibleCfgU()
{
	genAnsibleCfg $HOME/id_rsa no
}

genShraredSshKeys()
{
	if [ ! -d "$HOME/.conf"  -a ! -f "$HOME/.conf/id_rsa" ]; then
		rm -rf $HOME/.conf
		mkdir -p $HOME/.conf
		echo 'Host *
    User root
    Compression yes
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
   ' > $HOME/.conf/config
		ssh-keygen -t rsa -N "" -C "vm keys" -f $HOME/.conf/id_rsa
	fi

	acp all $HOME/.conf /tmp
	acmd all "cp -p /tmp/.conf/id_rsa* /tmp/.conf/config /root/.ssh/"
	acmd all "(echo; cat /root/.ssh/id_rsa.pub) >> /root/.ssh/authorized_keys"
	acmd all "chmod 600 /root/.ssh/id_rsa /root/.ssh/config"
}

##############################################################################################################
# LINODE CODE
##############################################################################################################
which linode-cli &>/dev/null
[ $? -eq 0 ] && LINODEC="$(which linode-cli)"

which linode-cli.exe &>/dev/null
[ $? -eq 0 ] && LINODEC="linode-cli.exe"

llist()
{
	$LINODEC linodes list $*
}

lcreate()
{
	if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
		echo "sshkeygen -t rsa"
		return 1
	fi

	NAME=${1:-"$(pwgen -1 8)"}
	shift
	PASSWD=${1:-"$(pwgen -1 18)"}
	shift
	PUBKEY=${1}
	shift
	[ -f "$PUBKEY" ] || PUBKEY="$HOME/.ssh/id_rsa.pub"
	EXTRA_TAGS=""
	while [ -n "$1" ]; do
		EXTRA_TAGS="$EXTRA_TAGS --tags $1"
		shift
	done
	echo "LINODE NAME  : $NAME"
	echo "ROOT PASSWORD: $PASSWD"
	echo "PUB KEY      : $PUBKEY"
    echo "PRIV KEY     : ${PUBKEY%.*}"
	echo "EXTRA PARAM  : $EXTRA_TAGS"

	info "CMD: "
	tmpFile=$(mktemp)
	echo  "#!/bin/bash" > $tmpFile
	echo "" >> $tmpFile
	echo -n "$LINODEC linodes create $LINODE_OPTIONS --root_pass $PASSWD --authorized_keys '" >> $tmpFile
	echo -n "$(sed -e "s/^M//" $PUBKEY)' " >> $tmpFile
	echo  "--private_ip true --label $NAME $EXTRA_TAGS" >> $tmpFile
	echo 'exit $?'>> $tmpFile
	info "$tmpFile"
	cat $tmpFile
	bash -x $tmpFile
	if [ $? -ne 0 ]; then
		error "FAILED CREATING $NAME LINODE"
		return 127
	fi
	rm -f $tmpFile
	true
	while [ $? -eq 0 ]; do
		echo -n ".."
		sleep 2s
		$LINODEC linodes list --text | grep $NAME | grep -qE '(booting|provisioning)'
	done
	echo
	$LINODEC linodes list
	echo -e "$( date "+%d-%m-%Y:%H-%M")\t$NAME\troot\t$PASSWD\t$PUBKEY\t${PUBKEY%.*}" | tee -a $HOME/.linode_access
	chmod 600 $HOME/.linode_access

    # Changing hostname with hostnamectl
    sleep 3s
    lchangeHostname $NAME
}

lchangeHostname()
{
    local NAME=$1
    local LHOSTNAME=${2:-"$NAME"}
    echo "LINODE NAME  : $NAME"
    echo "PRIV KEY     : ${PUBKEY%.*}"
    ssh -i ${PUBKEY%.*}  -o "StrictHostKeyChecking=no" root@$(lgetLinodePublicIp $NAME) "hostnamectl set-hostname $LHOSTNAME"
}

lssh()
{
    NAME=$1
    shift
    ssh -i ${PUBKEY%.*}  -o "StrictHostKeyChecking=no" root@$(lgetLinodePublicIp $NAME) "$*"
}

lgetLinodeId()
{
	$LINODEC linodes list --label $1 --text | tail -n1 | awk '{print $1}'
}

lgetLinodePublicIp()
{
	$LINODEC linodes list --label $1 --text | tail -n1 | awk '{print $7}'
}
lgetLinodePrivateIp()
{
	$LINODEC linodes list --label $1 --text | tail -n1 | awk '{print $8}'
}

lchangepasswd()
{
	true
}
ldelete()
{
	for lid in $($LINODEC linodes list --text | perl -ne  "/\s$1\s/ and print" | awk '{print $1}'); do
		info "DELETING $lid LINODES"
		llist --text | grep $lid
		$LINODEC linodes delete $lid
	done
	llist
}

lgenInventory()
{
	for tag in $($LINODEC tags list --text |grep -v label); do
		[ $(llist --text --tags $tag | wc -l) -eq 1 ] && continue
		echo "[$tag]"
		for srv in $(llist --text --tags $tag | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7}'); do
			lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
			lip=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
			echo "$lname ansible_host=$lip"
		done
		echo
	done > $ANSIBLE_INVENTORY

	cat $ANSIBLE_INVENTORY
}

lgenHosts()
{
	prefix=$1
	(
	#echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

echo "## START_LINODE_HOSTS"
for srv in $(llist --text | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7 ";" $8}'); do
			lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
			if [ -n "$prefix" ]; then
				echo "$lname" | grep -q "^${prefix}_"
				[ $? -eq 0 ] || continue
			fi
			lippub=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
			lippriv=$(echo "$srv"| tr ';' ' ' |awk '{print $3}')
			echo "$lippub	$lname	${lname}.public		${lname}.ext	${lname}.external"
			echo "$lippriv 		${lname}.private	${lname}.int	${lname}.internal"
		done

echo "## END_LINODE_HOSTS"
) > ${_DIR}/${prefix}generated_hosts
}

lcleanHosts()
{
	sed -i -n '1,/## START_LINODE_HOSTS/p;/## END_LINODE_HOSTS/,$p' /etc/hosts
	sed -i '/## START_LINODE_HOSTS/,/## END_LINODE_HOSTS/d' /etc/hosts
}

lsetupHosts()
{
	#lgenInventory
	lcleanHosts
	lgenHosts
	cat ${_DIR}/generated_hosts | tee -a /etc/hosts
}

lgenAlias()
{
	local PUBKEY=${1:-"$DEFAULT_PRIVATE_KEY"}
	[ -f "$PRIVKEY" ] || PRIVKEY=$HOME/.ssh/id_rsa
    PUBKEY=$(readlink -f $PUBKEY)
	for srv in $(llist --text | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7 ";" $8}'); do
		lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
		lippub=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
		alias ssh_$lname="ssh -o 'StrictHostKeyChecking=no' -X -i $PRIVKEY root@$lippub"
	done
}

lcopy()
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
    vip=$(lgetLinodePublicIp $lsrv)
    rsync -avz  -e "ssh -i ${PUBKEY%.*} -o 'StrictHostKeyChecking=no'" $fsource root@$vip:$fdest
    lRC=$(($lRC + $?))

    if [ -n "$own" ]; then
        lssh $lsrv "chown -R $own:$own $fdest"
        lRC=$(($lRC + $?))
    fi
    if [ -n "$mode" ]; then
        lssh $lsrv "chmod -R $mode $fdest"
        lRC=$(($lRC + $?))
    fi
    lssh $lsrv "ls -lsh $fdest"
    [ -z "$silent" ] && footer "SSH COPY $fsource ON $srv($vip):$fdest "
    return $lRC
}

lupdateScript()
{
    local lsrvs=${1:-"app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"}

    banner "UPDATE SCRIPTS $lsrvs"

    #set +x
    #set -x
    for lsrv in $($LINODEC linodes list --text | perl -ne  "/$1/ and print" | awk '{print $2}'); do
        lssh $lsrv "mkdir -p /opt/local/bin"
        title2 "TRANSFERT utils.sh TO $lsrv"
        lcopy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 755
        title2 "TRANSFERT bin scripts TO $lsrv"
        lcopy $lsrv $_DIR/scripts/bin/ /opt/local/bin root 755
    done
    footer "UPDATE SCRIPTS"
}

lexec()
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

        for srv in $($LINODEC linodes list --text | perl -ne  "/$lsrv/ and print" | awk '{print $2}'); do
            vip=$(lgetLinodePublicIp $srv)
            [ -n "$vip" ] || (warn "IGNORING $srv" ;continue)
            title2 "RUNNING SCRIPT $(basename $fcmd) ON $srv($vip) SERVER"
            (echo "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh";echo;cat $fcmd) | grep -v "#!" | ssh -T root@$vip -i ${PUBKEY%.*} -o "StrictHostKeyChecking=no" $INTERPRETER
            footer "RUNNING SCRIPT $(basename $fcmd) ON $srv($vip) SERVER"
            lRC=$(($lRC + $?))
        done
    done
    return $lRC
}

##############################################################################################################
# VAGRANT CODE
##############################################################################################################
vlist()
{
	(cd $VMS_DIR; sh status.sh $* )
}

vinfo()
{
	(cd $VMS_DIR; sh info.sh $*)
}

vdelete()
{
	(cd $VMS_DIR; sh destroy.sh $*)
}

vstart()
{
	(cd $VMS_DIR; sh start.sh $*)
}

vstop()
{
	(cd $VMS_DIR; sh stop.sh $*)
}

vgetPrivateIp()
{
	(
	grep '.vm.network "private_network", ip:' $VMS_DIR/Vagrantfile | \
	perl -pe 's/.vm.network "private_network", ip: "/:/g;s/", virtualbox__intnet: false//g;s/"//g'| \
	xargs -n 1 | \
	grep -E "^$1:" | \
	cut -d: -f2
	grep -E "\s$1\s" /etc/hosts | awk '{print $1}'
	) | sort -n | uniq
}

vgetLogicalNames()
{
	grep '.vm.network "private_network", ip:' $VMS_DIR/Vagrantfile | cut -d. -f1 |xargs -n1
}

vgetLogicalGroups()
{
	vgetLogicalNames | perl -pe 's/\d*$//g' | sort | uniq
}


vgenInventory()
{
	for tag in $(vgetLogicalGroups); do
		echo "[$tag]"
		for srv in $(vgetLogicalNames| grep -E "^$tag"); do
			lip=$(vgetPrivateIp $srv)
			echo "$srv ansible_host=$lip"
		done
		echo
	done > $ANSIBLE_INVENTORY

	cat $ANSIBLE_INVENTORY
}

vgenAlias()
{
	local tkey=${1:-"$HOME/.conf/id_rsa"}
    for srv in $(vgetLogicalNames); do
		lip=$(vgetPrivateIp $srv)
		alias ssh_$srv="ssh -i $tkey root@$lip"
	done
    export DEFAULT_PRIVATE_KEY="$HOME/.conf/id_rsa"
}

vssh_get_host_pattern_list()
{
    local patt=$1

    (
		grep '.vm.network "private_network", ip:' $VMS_DIR/Vagrantfile |grep -e "$patt" | cut -d. -f1
		grep -vE '^#' /etc/hosts | awk '{print $2}'| grep -v '.private' |grep -e "$patt"
	) | sort | uniq | xargs -n 1
}

vssh_get_host_list()
{
    echo $* | perl -pe 's/[, :]/\n/g' | while read -r line
    do
        echo $line | grep -q '*'
        if [ $? -eq 0 ]; then
            #echo "PATERN HOST: $line"
            vssh_get_host_pattern_list $line
        else
            echo $line
        fi
    done | sort | uniq | xargs -n 1
}

vssh_exec()
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

        for srv in $(vssh_get_host_list $lsrv); do
            vip=$(vgetPrivateIp $srv)
            [ -n "$vip" ] || (warn "IGNORING $srv" ;continue)
            title2 "RUNNING SCRIPT $(basename $fcmd) ON $srv($vip) SERVER"
            (echo "[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh";echo;cat $fcmd) | grep -v "#!" | ssh -T root@$vip -i $DEFAULT_PRIVATE_KEY $INTERPRETER
            footer "RUNNING SCRIPT $(basename $fcmd) ON $srv($vip) SERVER"
            lRC=$(($lRC + $?))
        done
    done
    return $lRC
}

vssh_cmd()
{
    local lsrv=$1
    local lRC=0
    local fcmd=$2
    local silent=$3

    for srv in $(vssh_get_host_list $lsrv); do
        vip=$(vgetPrivateIp $srv)
        [ -n "$vip" ] || (warn "IGNORING $srv" ;continue)
        [ -z "$silent" ] && title2 "RUNNING UNIX COMMAND: $fcmd ON $srv($vip) SERVER"
        [ -n "$silent" ] && echo -ne "$srv\t$fcmd\t"
        ssh -T root@$vip -i $DEFAULT_PRIVATE_KEY "$fcmd"
        lRC=$(($lRC + $?))
        [ -n "$silent" ] && echo
        [ -z "$silent" ] && footer "RUNNING UNIX COMMAND: $fcmd ON $srv($vip) SERVER"
    done
    return $lRC
}

vssh_copy()
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
    for srv in $(vssh_get_host_list $lsrv); do
        vip=$(vgetPrivateIp $srv)
        [ -n "$vip" ] || (warn "IGNORING $srv" ;continue)
        [ -z "$silent" ] && title2 "SSH COPY $fsource ON $srv($vip):$fdest "

        rsync -avz  -e "ssh -i $DEFAULT_PRIVATE_KEY" $fsource root@$vip:$fdest
        lRC=$(($lRC + $?))

        if [ -n "$own" ]; then
         vssh_cmd $srv "chown -R $own:$own $fdest" silent
         lRC=$(($lRC + $?))
       fi
       if [ -n "$mode" ]; then
         vssh_cmd $srv "chmod -R $mode $fdest" silent
         lRC=$(($lRC + $?))
       fi
       [ -z "$silent" ] && footer "SSH COPY $fsource ON $srv($vip):$fdest "
       #lRC=$(($lRC + $?))
    done
    return $lRC
}

vgenAliasU()
{
	vgenAlias $VMS_DIR/id_rsa
}

vsetupTempAnsible()
{
	for srv in $(vlist |grep running |awk '{ print $1}' | xargs -n 20); do
		echo $srv
		ssh -i $VMS_DIR/id_rsa root@$(vgetPrivateIp $srv) "mkdir -p /var/tmp2;chmod -R 777 /var/tmp2"
	done
}

vsetupVMs()
{
	$1
	genAnsibleCfgU
	genShraredSshKeys
	genAnsibleCfg
	vgenAlias
    $2
}

vupdateScript()
{
	local lsrv=${1:-"app1,mgt1,proxy1,proxy2,dbsrv1,dbsrv2,dbsrv3"}
	banner "UPDATE SCRIPTS"
	vssh_cmd $lsrv "mkdir -p /opt/local/bin"
	title2 "TRANSFERT utils.sh TO $lsrv"
	vssh_copy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 755
	title2 "TRANSFERT bin scripts TO $lsrv"
	vssh_copy $lsrv $_DIR/scripts/bin/ /opt/local/bin root 755
    footer "UPDATE SCRIPTS"
}

local_updateScript()
{
    banner "UPDATE SCRIPTS"
    mkdir -p /opt/local/bin
    title2 "TRANSFERT utils.sh TO /etc/profile.d"
    cp -v $_DIR/scripts/utils.sh /etc/profile.d/utils.sh
    chown root: /etc/profile.d/utils.sh
    chmod 755 /etc/profile.d/utils.sh
    title2 "TRANSFERT bin scripts TO /opt/local"
    cp -R $_DIR/scripts/bin /opt/local
    chown -R root: /opt/local/bin
    chmod -R 755 /opt/local/bin
    footer "UPDATE SCRIPTS"
}
