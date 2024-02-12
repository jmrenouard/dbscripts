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

dnf -y install sublime-text kernel-devel kernel-headers gcc make perl wget pigz 
dnf -y install VirtualBox-6.1.x86_64

dnf -y install vagrant

curl -O http://downloadfiles.idera.com/products/IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
unzip IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
dnf -y install ./IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.rpm

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
