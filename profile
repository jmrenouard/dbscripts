#!/bin/sh

if [ "$0" != "/bin/bash" -a "$0" != "-bash" ]; then
	_DIR="$(dirname "$(readlink -f "$0")")"
else
	_DIR="$(readlink -f ".")"
fi

export VMS_DIR="$(readlink -f ".")/vms"
[ -d "${_DIR}/vms" ] && export VMS_DIR="${_DIR}/vms"

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


now() {
    echo "$(date "+%F %T %Z")"
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

    [ $lRC -eq 0 ] && info "$* ENDED SUCCESSFULLY"
    [ $lRC -eq 0 ] || warn "$* ENDED WITH WARNING OR ERROR"
    title1 "END: $*"
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
alias srsync="sudo rsync  -e 'ssh -l root'"
alias pass='pwgen -1 18'

alias s=sudo
alias sssh='sudo ssh -l root'
alias srsync="sudo rsync  -e 'ssh -l root'"

alias gst="git status"
alias ga="git add"
alias gam="git status | grep modified: | cut -d: -f2 | xargs -n 1 git add"
alias gad="git status | grep deleted:  | cut -d: -f2 | xargs -n1 git rm -f"

alias h=history
rl()
{
	cd ${_DIR}
	source ${_DIR}/profile
}

# ansible
export ANSIBLE_LOAD_CALLBACK_PLUGINS=1
export ANSIBLE_STDOUT_CALLBACK=debug
export ANSIBLE_INVENTORY=${_DIR}/inventory
export ANSIBLE_CONFIG=${_DIR}/.ansible.cfg

alias an="time ansible -f $(nproc)"
alias anh="time ansible --list-hosts"
alias anv="ANSIBLE_STDOUT_CALLBACK=debug time ansible -f $(nproc) -v"
alias and="ANSIBLE_STDOUT_CALLBACK=debug time ansible -f $(nproc) -v --step"

# Alias pour ansible-playbook
alias ap="time ansible-playbook -f $(nproc)"
alias apv="ANSIBLE_STDOUT_CALLBACK=debug time ansible-playbook -f $(nproc) --verbose"
alias apd="ANSIBLE_STDOUT_CALLBACK=debug time ansible-playbook -f $(nproc) --verbose --step"

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

gcm()
{
        git commit -m "$@"
}

acp()
{

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) --verbose $1 -mcopy -a "src=$2 dest=$3"

    if [ -n "$4" ]; then
        acmd $1 "chown -R $4.$4 $3"
    fi
}

aexec()
{
    local target=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) --verbose $target -mscript -a "$*"
}

auexec()
{
    local target=$1
    shift
    local user=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
    ansible -f $(nproc) --verbose $target -mscript -b --become-user=$user -a "$*"
}
apexec()
{
    local target=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"debug"}
    ansible -f $(nproc) --verbose $target -mscript -b --become-user=postgres -a "$*"
}
acmd()
{
    local target=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"debug"}
    ansible -f $(nproc) --verbose $target -mshell -a "$*"
}

aucmd()
{
    local target=$1
    shift
    local user=$1
    shift

    export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"debug"}
    echo "stdout_calback: $ANSIBLE_STDOUT_CALLBACK"
    ansible -f $(nproc) --verbose $target -mshell -b --become-user=$user -a "$*"
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
	[ -f "$HOME/id_rsa" ] && rm -f $HOME/id_rsa
	echo "[defaults]
system_warnings=False
remote_user=root
private_key_file=$HOME/.conf/id_rsa
inventory =${_DIR}/inventory
[ssh_connection]
ssh_args = -o ControlMaster=no
scp_if_ssh=True" > $ANSIBLE_CONFIG

	echo "Fichier de config: $ANSIBLE_CONFIG"
	cat $ANSIBLE_CONFIG
}

genAnsibleCfgU()
{
	if [ ! -f "$HOME/id_rsa" ]; then
		cp $VMS_DIR/id_rsa $HOME
		chmod 600 $HOME/id_rsa
	fi
	echo "[defaults]
system_warnings=False
remote_user=root
private_key_file=$HOME/id_rsa
inventory =${_DIR}/inventory
[ssh_connection]
ssh_args = -o ControlMaster=no
scp_if_ssh=True" > $ANSIBLE_CONFIG

	echo "Fichier de config: $ANSIBLE_CONFIG"
	cat $ANSIBLE_CONFIG
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
llist()
{
	linode-cli linodes list $*
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
	EXTRA_TAGS=""
	while [ -n "$1" ]; do
		EXTRA_TAGS="$EXTRA_TAGS --tags $1"
		shift
	done
	echo "LINODE NAME  : $NAME"
	echo "ROOT PASSWORD: $PASSWD"
	echo "EXTRA PARAM  : $EXTRA_TAGS"

	info "CMD: linode-cli linodes create --root_pass "$PASSWD" --authorized_keys "$(cat $HOME/.conf/id_rsa.pub)" --private_ip true --label $NAME $EXTRA_TAGS"
	linode-cli linodes create --root_pass "$PASSWD" --authorized_keys "$(cat $HOME/.conf/id_rsa.pub)" --private_ip true --label $NAME $EXTRA_TAGS
	true
	while [ $? -eq 0 ]; do
		echo -n ".."
		sleep 2s
		linode-cli linodes list --text | grep $NAME | grep -qE '(booting|provisioning)'
	done
	echo
	linode-cli linodes list
}

ldelete()
{
	for lid in $(linode-cli linodes list --text | perl -ne  "/\s$1\s/ and print" | awk '{print $1}'); do
		info "DELETING $lid LINODES"
		llist --text | grep $lid
		linode-cli linodes delete $lid
	done
	llist
}

lgenInventory()
{
	for tag in $(linode-cli tags list --text |grep -v label); do
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
	(
	echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

### SPECIFIC CONFIG ###"
for srv in $(llist --text | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7 ";" $8}'); do
			lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
			lippub=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
			lippriv=$(echo "$srv"| tr ';' ' ' |awk '{print $3}')
			echo "$lippub	$lname	${lname}.public		${lname}.ext	${lname}.external"
			echo "$lippriv 		${lname}.private	${lname}.int	${lname}.internal"
		done

echo "### END SPECIFIC CONFIG ###"
) > ${_DIR}/generated_hosts
cat ${_DIR}/generated_hosts
}

lsetupHosts()
{
	lgenInventory
	lgenHosts
	acp all ${_DIR}/generated_hosts /tmp
	acmd all "cat /tmp/generated_hosts > /etc/hosts"
	acmd all "cat /etc/hosts"
}

lgenAlias()
{
	for srv in $(llist --text | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7 ";" $8}'); do
		lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
		lippub=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
		alias ssh_$lname="ssh -o 'StrictHostKeyChecking=no ForwardX11=no' -X -i $HOME/.conf/id_rsa root@$lippub"
	done
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
	grep '.vm.network "private_network", ip:' $VMS_DIR/Vagrantfile | perl -pe 's/.vm.network "private_network", ip: "/:/g;s/", virtualbox__intnet: false//g'| xargs -n 1 | grep -E "^$1:" | cut -d: -f2	
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
	for srv in $(vgetLogicalNames); do
		lip=$(vgetPrivateIp $srv)
		alias ssh_$srv="ssh -i $HOME/.conf/id_rsa root@$lip"
	done
}

vgenAliasU()
{
	for srv in $(vgetLogicalNames); do
		lip=$(vgetPrivateIp $srv)
		alias ssh_$srv="ssh -i $VMS_DIR/id_rsa root@$lip"
	done
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
	vstart
	genAnsibleCfgU
	genShraredSshKeys
	genAnsibleCfg
	vgenAlias
}
