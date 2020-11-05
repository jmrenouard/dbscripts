#!/bin/sh
echo '---------------------------------------------------'
echo " * PROVISIONNING ANSIBLE "
echo '---------------------------------------------------'
sudo yum -y install python36-virtualenv
sudo pip3 install virtualenvwrapper

[ -d "/data/envs/ansible" ] && sudo rm -rf /data/envs/ansible
sudo mkdir -p /data/envs

echo "export PATH=$PATH:.:/usr/local/bin
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/bin/virtualenv-3.6
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export WORKON_HOME=/data/envs
export ANSIBLE_INVENTORY=/data/inventory
source /usr/local/bin/virtualenvwrapper.sh
" >> $HOME/.bash_profile
cat $HOME/.bash_profile
source $HOME/.bash_profile
[ -d "$WORKON_HOME/ansible" ] || mkvirtualenv ansible
workon ansible
pip install ansible molecule

(
	cat <<'EndOfScript'
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



