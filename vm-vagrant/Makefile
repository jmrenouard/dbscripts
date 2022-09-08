VGT=vagrant
#VGT=vagrant.exe
VBOXM=VBoxManage
#VBOXM=VBoxManage.exe

VBGUEST_ISO="C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
CONF_FILE=./server.json
up:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) up

status:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) status

provision:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) provision

halt:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) halt

reload:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) reload

destroy: halt
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) destroy --force

cleanup:
	rm -rf Vagrantfile puttyreg.reg id_rsa* privatekey.ppk bashrc .vagrant ansible.cfg inventory log cache

installvbguest:
	export VAGRANT_DEFAULT_PROVIDER="virtualbox"
	$(VGT) vbguest --do install --iso $(VBGUEST_ISO)

generate_keys:
	rm -rf id_rsa* privatekey.ppk
	ssh-keygen -t rsa -f ./id_rsa_vm -q -P ""
	puttygen id_rsa_vm -o privatekey.ppk

generate_vagrantfile:
	echo "## Generation Vagrantfile"
	cat $(CONF_FILE) | j2 -f json templates/Vagrantfile.j2 > Vagrantfile

generate_puttyreg:
	echo "## Generation du registre pour Putty"
	cat $(CONF_FILE) | j2 -f json templates/puttyreg.reg.j2 > puttyreg.reg

generate_bashrc:
	echo "## Generation des alias Shell"
	cat $(CONF_FILE) | j2 -f json templates/alias_ssh.j2 > bashrc

generate_conf_ansible:
	echo "## Generation du fichier Ansible.cfg"
	cat $(CONF_FILE) | j2 -f json templates/ansible.cfg.j2 > ansible.cfg

	echo "## Generation du fichier Inventaire"
	cat $(CONF_FILE) | j2 -f json templates/inventory.j2 > inventory
	[ -d "log" ] || mkdir log
	[ -d "cache" ] || mkdir cache

install_dep_deb:
	pip install j2cli ansible
	apt -y install puttygen

install_dep_rh:
	pip3 install j2cli ansible
	dnf -y install putty

generate: generate_keys generate_puttyreg generate_conf_ansible generate_bashrc generate_vagrantfile

loadmod:
	sudo modprobe vboxdrv
	sudo modprobe vboxnetadp
	sudo /sbin/vboxconfig

getinet:
	VBoxManage.exe list bridgedifs| grep -E '^Name:'| perl -pe 's/Name:\s+//g' |sort -n