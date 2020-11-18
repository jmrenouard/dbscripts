#!/bin/sh
echo '---------------------------------------------------'
echo " * PROVISIONNING ANSIBLE "
echo '---------------------------------------------------'

for aversion in 2.8 2.9 2.10; do
	echo '---------------------------------------------------'
	echo " * PROVISIONNING ANSIBLE $aversion"
	echo '---------------------------------------------------'
	atag=$(echo $aversion | sed 's/\.//g')
	if [ ! -d "$HOME/ansible${atag}" ]; then
		python -mvenv ansible${atag}
		source ./ansible${atag}/bin/activate
		pip install --upgrade pip
		pip install "ansible==$aversion" ansible-lint molecule
	fi
done

(
	cat <<'EndOfScript'

venv_activate()
{
	cd $HOME
	source ${1:-"ansible210"}/bin/activate

}

export ANSIBLE_INVENTORY=/data/inventory
export ANSIBLE_CONFIG=/data/ansible.cfg

alias s=sudo
alias h=history
alias hserver='python -m http.server 8000'

alias an="time ansible -f $(nproc)"

alias anh="time ansible --list-hosts"

alias anl="time ansible-lint"

alias anv="ANSIBLE_STDOUT_CALLBACK=debug time ansible -f $(nproc) --verbose"
alias apv="ANSIBLE_STDOUT_CALLBACK=debug time ansible-playbook -f $(nproc) --verbose"

alias apc="time ansible-playbook --syntax-check"
alias aph="time ansible-playbook --list-hosts"
alias apt="time ansible-playbook --list-tasks"

acp()
{
export ANSIBLE_STDOUT_CALLBACK=${ANSIBLE_STDOUT_CALLBACK:-"oneline"}
ansible -f $(nproc) -–become --verbose $1 -mcopy -a "src=$2 dest=$3"

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
ansible -f $(nproc) --verbose $target -mshell -b --become-user=$user -a "$*"
}
EndOfScript
) | sudo tee /etc/profile.d/ansible.sh

sudo chmod 755 /etc/profile.d/ansible.sh
source /etc/profile.d/ansible.sh


sudo rsync -av ~vagrant/ansible2* /root
sudo chown -R root.root /root/ansible2*
