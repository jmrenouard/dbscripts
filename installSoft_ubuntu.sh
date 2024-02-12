#!/bin/bash

init_soft()
{
# Vscode
sudo apt update

sudo apt install software-properties-common apt-transport-https wget -y
#if [ ! -f "/etc/apt/sources.list.d/vscode.list" ]; then
sudo rm -f /etc/apt/sources.list.d/vscode.list
wget -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg
echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | \
sudo tee /etc/apt/sources.list.d/vscode.list
#fi 

# sublime text
#if [ ! -f "/etc/apt/sources.list.d/sublime-text.list" ]; then
wget -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/sublimetext-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sublimetext-keyring.gpg] https://download.sublimetext.com/ apt/stable/" | \
sudo tee /etc/apt/sources.list.d/sublime-text.list
#fi

#if [ ! -f "/etc/apt/sources.list.d/virtualbox.list" ]; then
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc  | sudo gpg --dearmor | sudo tee /usr/share/keyrings/virtualbox.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian jammy contrib"| \
sudo tee /etc/apt/sources.list.d/virtualbox.list
#fi

#if [ ! -f "/etc/apt/sources.list.d/hashicorp.list" ]; then

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
#fi

#if [ ! -f "/etc/apt/sources.list.d/google.list" ]; then
rm -f /etc/apt/sources.list.d/google.list
#wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
#sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> \
#sudo tree -a /etc/apt/sources.list.d/google.list'
#fi
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
#sudo apt-get install -f
#if [ ! -f "/etc/apt/sources.list.d/docker.list" ]; then

curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/dbeaver.gpg
echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#fi 

sudo apt update
sudo apt install -y code virtualbox-7.0 vagrant sublime-text default-jdk dbeaver-ce
sudo apt -y install linux-headers-generic gcc make perl wget pigz git make python3 python3-pip netcat dos2unix dkms
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

sudo apt upgrade -y

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get -y remove $pkg; done

df -Ph

sudo apt -y install vim-gtk3
#exit 0
}
init_vms()
{
#  sudo bash ubuntu-mainline-kernel.sh -i v5.15.0

  sudo /sbin/vboxconfig
  cd vms 
  sh init_vagrant.sh

  sh start.sh
}

init_conf()
{
  sed -i '/source $HOME\/dbscripts\/profile/d' $HOME/.bashrc
  echo '[ -f "$HOME/dbscripts/profile" ] && source $HOME/dbscripts/profile' >> $HOME/.bashrc
  source $HOME/.bashrc
}

init_jupyter()
{
	sudo apt install pandoc -y
	sudo pip3 install notebook bash_kernel jupyter nbconvert
  python3 -m bash_kernel.install
}

[ "$1" = "" -o "$1" = "initsoft" ] && init_soft
[ "$1" = "" -o "$1" = "initvms" ] && init_vms
[ "$1" = "" -o "$1" = "initconf" ] && init_conf
[ "$1" = "" -o "$1" = "initjupy" ] && init_jupyter