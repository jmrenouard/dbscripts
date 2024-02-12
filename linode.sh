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
    local NAME=$1
    local PRIVKEY=${2:-"$DEFAULT_PRIVATE_KEY"}
    shift
    ssh -i ${PRIVKEY}  -o "StrictHostKeyChecking=no" root@$(lgetLinodePublicIp $NAME) "$*"
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
    local ANSIBLE_INVENTORY="${1:-"./inventory"}"
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
    echo "
[local]
127.0.0.1 ansible_connection=local">>$ANSIBLE_INVENTORY
	cat $ANSIBLE_INVENTORY
}

lgenAnsibleConfig()
{
    local ANSIBLE_CONFIG="${1:-"./ansible.cfg"}"
    echo "[defaults]
#deprecation_warnings=False
#command_warnings=False
#ansible_warnings=False
forks=$(nproc)
fact_caching=jsonfile
fact_caching_connection=./cache
fact_caching_timeout = 7200
host_key_checking = False
timeout=15
log_path = ./logs/ansible.log

bin_ansible_callbacks=True
callbacks_enabled = timer, yaml, json, profile_tasks, profile_roles, counter_enabled
stdout_callback=debug
#stdout_callback=dense
junit_output_dir=./output
output_dir=./logs
private_key_file=${DEFAULT_PRIVATE_KEY}
remote_user = root

[inventory]
cache=True
#enable_plugins = advanced_host_list, constructed, yaml

"> $ANSIBLE_CONFIG
    (cd $(dirname $ANSIBLE_CONFIG);mkdir -p logs cache output)
    #cat $ANSIBLE_CONFIG
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

lgenAlias()
{
	local PRIVKEY=${1:-"$DEFAULT_PRIVATE_KEY"}
	[ -f "$PRIVKEY" ] || PRIVKEY=$HOME/.ssh/id_rsa
    PRIVKEY=$(readlink -f $PRIVKEY)
	for srv in $(llist --text | grep -Ev '(label|ipv4)' | awk '{ print $2 ";" $7 ";" $8}'); do
		lname=$(echo "$srv"| tr ';' ' ' |awk '{print $1}')
		lippub=$(echo "$srv"| tr ';' ' ' |awk '{print $2}')
		alias ssh_$lname="ssh -o 'StrictHostKeyChecking=no' -X -i $PRIVKEY root@$lippub"
	done
    cat ./generated_hosts | tee -a /etc/hosts
}

lsetupHosts()
{
    lgenAConfig
    lgenInventory
    lcleanHosts
    lgenHosts
    lgenAlias
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
