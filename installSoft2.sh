#!/bin/sh


if [ "$1" = "check" ]; then
	rpm -qa | grep -Ei '(vagrant|virtualbox|iderasql|sublime|oracle)'
	exit 0
fi

dnf -y install dnf-plugins-core dnf-utils

rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
rpm -v --import https://www.virtualbox.org/download/oracle_vbox.asc

yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum-config-manager --add-repo  http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

dnf -y install sublime-text kernel-devel kernel-headers gcc make perl wget pigz git make python3 python3-pip
dnf -y install VirtualBox-6.1.x86_64

dnf -y install vagrant

dnf -y install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

dnf -y install https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm

rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

dnf -y install code

dnf -y upgrade
exit 0
yum install cloud-utils dos2unix -y
df

growpart /dev/sda 1
growpart /dev/sda 2
growpart /dev/sda 3

df -Ph
lvresize -l +100%FREE /dev/mapper/cl-root
xfs_growfs /

df -Ph
exit 0
cd vms 
sh init_vagrant.sh

sh start.sh
