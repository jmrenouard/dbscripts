#!/bin/sh


if [ "$1" = "check" ]; then
	dpkg -l | grep -Ei '(vagrant|virtualbox|iderasql|sublime|oracle)'
	exit 0
fi
# Vscode
apt update
sudo apt install software-properties-common apt-transport-https wget -y
wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/vscode.gpg
echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | sudo tee /etc/apt/sources.list.d/vscode.list

# sublime text
wget -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/sublimetext-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/sublimetext-keyring.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc  | gpg --dearmor | sudo tee /usr/share/keyrings/virtualbox.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian jammy contrib"| sudo tee /etc/apt/sources.list.d/virtualbox.list

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> \
/etc/apt/sources.list.d/google.list'

curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/dbeaver.gpg
echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list

apt update
apt install -y code virtualbox-7.0 vagrant sublime-text google-chrome-stable default-jdk dbeaver-ce
apt -y install kernel-devel kernel-headers gcc make perl wget pigz git make python3 python3-pip nc dos2unix
apt upgrade -y
df -Ph

exit 0
cd vms 
sh init_vagrant.sh

sh start.sh
