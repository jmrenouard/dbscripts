
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
	local lsrv=${1:-"$all_vms"}
	banner "UPDATE SCRIPTS"
	vssh_cmd $lsrv "mkdir -p /opt/local/bin"
	title2 "TRANSFERT utils.sh TO $lsrv"
	vssh_copy $lsrv $_DIR/scripts/utils.sh /etc/profile.d/utils.sh root 755
	title2 "TRANSFERT mysql.utils.sh TO $lsrv"
 	vssh_copy $lsrv $_DIR/scripts/utils.mysql.sh /etc/profile.d/utils.mysql.sh root 755
        title2 "TRANSFERT bin scripts TO $lsrv"
	vssh_copy $lsrv $_DIR/scripts/bin/ /opt/local/bin root 755
    footer "UPDATE SCRIPTS"
}

local_updateScript()
{
    banner "LOCAL UPDATE SCRIPTS"
    mkdir -p /opt/local/bin
    title2 "TRANSFERT utils.*.sh TO /opt/local/bin"
    rsync -av $_DIR/scripts/utils*.sh /opt/local/bin
    
    title2 "TRANSFERT bin scripts TO /opt/local"
    rsync -av $_DIR/scripts/bin /opt/local
    
    chown -R root: /opt/local/bin
    chmod -R 755 /opt/local/bin
    footer "LOCAL UPDATE SCRIPTS"
}
