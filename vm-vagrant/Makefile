VGT=vagrant
VGT=vagrant.exe

VBGUEST_ISO="C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
CONF_FILE=./server.json
up:
	$(VGT) up 

status:
	$(VGT) status

provision:
	$(VGT) provision

halt:
	$(VGT) halt

reload:
	$(VGT) reload

destroy: halt
	$(VGT) destroy --force

cleanup:
	rm -rf Vagrantfile puttyreg.reg id_rsa* privatekey.ppk bashrc .vagrant ansible.cfg inventory log cache

installvbguest:
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

generate_bachrc:
	echo "## Generation des alias Shell"
	cat $(CONF_FILE) | j2 -f json templates/alias_ssh.j2 > bashrc

generate_conf_ansible:
	echo "## Generation du fichier Ansible.cfg"
	cat $(CONF_FILE) | j2 -f json templates/ansible.cfg.j2 > ansible.cfg

	echo "## Generation du fichier Inventaire"
	cat $(CONF_FILE) | j2 -f json templates/inventory.j2 > inventory
	[ -d "log" ] || mkdir log
	[ -d "cache" ] || mkdir cache

install_dep:
	pip install j2cli ansible
	apt -y install puttygen

generate: generate_keys generate_puttyreg generate_conf_ansible generate_bachrc generate_vagrantfile

loadmod:
	sudo modprobe vboxdrv
	sudo modprobe vboxnetadp
	sudo /sbin/vboxconfig
