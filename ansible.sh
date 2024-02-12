##############################################################################################################
# ANSIBLE CODE
##############################################################################################################
##########################################
# Functions ANSIBLE
##########################################

export ANSIBLE_LOAD_CALLBACK_PLUGINS=1
export ANSIBLE_STDOUT_CALLBACK="minimal"
export ANSIBLE_EXTRA_OPTIONS=""

export ANSIBLE_INVENTORY=${_DIR}/inventory
[ -f "./inventory" ] && export ANSIBLE_INVENTORY=$(readlink -f "./inventory")

export ANSIBLE_CONFIG=${_DIR}/.ansible.cfg
[ -f "./ansible.cfg" ] && export ANSIBLE_CONFIG=$(readlink -f "./ansible.cfg")

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


alias aping="ansible -v -mping"

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

unalias ap 2>/dev/null
ap()
{
    if [ -f "./vault.txt" -a -f "./password.yml" ]; then
        echo "CMD: time ansible-playbook -f $(nproc) -e '@password.yml' --vault-password-file=vault.txt $*"
        time ansible-playbook -f $(nproc) -e '@password.yml' --vault-password-file=vault.txt $*
        return $?
    fi
    echo "CMD: time ansible-playbook -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $*"
    time ansible-playbook -f $(nproc) ${ANSIBLE_EXTRA_OPTIONS} $*
}

unalias apv 2>/dev/null
apv()
{
    ANSIBLE_EXTRA_OPTIONS="--verbose" 
    ap $*
}

unalias apd 2>/dev/null
apd()
{
    ANSIBLE_EXTRA_OPTIONS="--verbose --step" 
    ap $*
}

update_aroles()
{
    [ -d "./log" ] || mkdir ./log
    [ -d "./cache" ] || mkdir ./cache
    if [ ! -f "./requirements.yml" ]; then
        fail "NO ./requirements.yml FILE"
        return 127
    fi
    rm -rf roles/*
    ansible-galaxy install -r ./requirements.yml --force
}

update_aroles()
{
    [ -d "./log" ] || mkdir ./log
    [ -d "./cache" ] || mkdir ./cache
    if [ ! -f "./requirements.yml" ]; then
        fail "NO ./requirements.yml FILE"
        return 127
    fi
    rm -rf roles/*
    ansible-galaxy install -r ./requirements.yml --force
    ls -ls roles/
}
alias get_jtemplate="find . -type f -iname '*.j2'"

update_alroles()
{
    if [ ! -f "./requirements.yml" ]; then
        fail "NO ./requirements.yml FILE"
        return 127
    fi
    needed_roles=$(grep src requirements.yml | rev | cut -d/ -f1 | cut -d. -f 2 | rev)
    rm -rf roles/*
    for role in $needed_roles; do
        (
        cd ./roles
        role_path=$(readlink -f ../../$role) 
        if [ -d "$role_path" ]; then 
            ln -sf $role_path
        else 
            fail "ROLE $role($role_path) IS MISSING IN LOCAL"
        fi   
        )
    done 
    ls -ls roles/
}

load_ainventory()
{
    for inv in $1 $(pwd)/inventory $HOME/GIT_REPOS/inventory-infra-b2c/$1/hosts; do
        if [ -f "$1" -o -d "$1" ]; then
            export ANSIBLE_INVENTORY=$(readlink -f $inv)
            echo "ANSIBLE_INVENTORY: $ANSIBLE_INVENTORY"
            return 0
        fi
    done  
    echo 'ERROR: inventory MISSING'
    return 127
}

load_aconfig()
{
    for cfg in $1 $(pwd)/ansible.cfg; do
        if [ -f "$cfg" ]; then
            export ANSIBLE_CONFIG=$(readlink -f $cfg)
            echo "ANSIBLE_CONFIG: $ANSIBLE_CONFIG"
            return 0
        fi
    done
    echo 'ERROR: ansible.cfg MISSING'
    return 127
}

get_aconfig()
{
    echo "ANSIBLE_CONFIG: $ANSIBLE_CONFIG"
    echo "ANSIBLE_INVENTORY: $ANSIBLE_INVENTORY"
}

dump_aconfig()
{
    if [ -f "$ANSIBLE_INVENTORY" ]; then
        title1 "INVENTORY: $ANSIBLE_INVENTORY"
        cat $ANSIBLE_INVENTORY
    fi
    if [ -d "$ANSIBLE_INVENTORY" ]; then
        title1 "DIR INVENTORY: $ANSIBLE_INVENTORY"
        [ -f "$ANSIBLE_INVENTORY/hosts" ] && cat $ANSIBLE_INVENTORY/hosts
        [ -f "$ANSIBLE_INVENTORY/inventory" ] && cat $ANSIBLE_INVENTORY/inventory
    fi
    sep2
    if [ -f "$ANSIBLE_CONFIG" ]; then
        title1 "CONFIG: $ANSIBLE_CONFIG"
        cat $ANSIBLE_CONFIG
    else 
        error "ANSIBLE_CONFIG MISSING !!!!"
    fi
}

alint_dir()
{
    local rdir=${1:-"."}
    title2 "ANSIBLE LINT $rdir"
    (
        cd $rdir 
        export ANSIBLE_CONFIG=$rdir/ansible.cfg
        ansible-lint -v .
    )
}

alint_dirs()
{
    local rdir=${1:-"."}
    for d in $rdir/*; do
        [ -d "$d" ] || continue
        [ -d "$d/tasks" -o -f "$d/playbook.yaml" -o -f "$d/playbook.yml" ] || continue
        alint_dir $d
    done
}

mirror_ansible_collection()
{
        set -x
        if [ ! -d "$HOME/GIT_REPOS/ansible/community.general" ]; then 
            mkdir -p $HOME/GIT_REPOS/ansible/
        fi
        cd $HOME/GIT_REPOS/ansible
        git pull https://github.com/ansible-collections/community.general.git
        git checkout -b 4.5.0
        cd $HOME/GIT_REPOS/community.general
        rsynv -av --exclude=.git $HOME/GIT_REPOS/ansible/community.general/ .
        git status
}

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
#command_warnings=False
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
