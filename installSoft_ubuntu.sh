#!/bin/sh


if [ "$1" = "check" ]; then
	dpkg -l | grep -Ei '(vagrant|virtualbox|iderasql|sublime|oracle)'
	exit 0
fi
# Vscode
apt update

if [ ! -f "/etc/apt/sources.list.d/vscode.list" ]; then
sudo apt install software-properties-common apt-transport-https wget -y
wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/vscode.gpg
echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | \
sudo tee /etc/apt/sources.list.d/vscode.list
fi 

# sublime text
if [ ! -f "/etc/apt/sources.list.d/sublime-text.list" ]; then
wget -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/sublimetext-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sublimetext-keyring.gpg] https://download.sublimetext.com/ apt/stable/" | \
sudo tee /etc/apt/sources.list.d/sublime-text.list
fi

if [ ! -f "/etc/apt/sources.list.d/virtualbox.list" ]; then
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc  | gpg --dearmor | sudo tee /usr/share/keyrings/virtualbox.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian jammy contrib"| \
sudo tee /etc/apt/sources.list.d/virtualbox.list
fi

if [ ! -f "/etc/apt/sources.list.d/hashicorp.list" ]; then

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
fi

if [ ! -f "/etc/apt/sources.list.d/google.list" ]; then

wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> \
/etc/apt/sources.list.d/google.list'
fi

if [ ! -f "/etc/apt/sources.list.d/docker.list" ]; then

curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/dbeaver.gpg
echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi 

apt update
apt install -y code virtualbox-7.0 vagrant sublime-text google-chrome-stable default-jdk dbeaver-ce
apt -y install kernel-devel kernel-headers gcc make perl wget pigz git make python3 python3-pip nc dos2unix
apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker $USER

apt upgrade -y

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

df -Ph

exit 0
cd vms 
sh init_vagrant.sh

sh start.sh
