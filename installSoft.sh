#!/bin/sh


if [ "$1" = "check" ]; then
	rpm -qa | grep -Ei '(vagrant|virtualbox|iderasql|sublime|oracle)'
	exit 0
fi


rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
rpm -v --import https://www.virtualbox.org/download/oracle_vbox.asc

dnf -y install dnf-plugins-core dnf-utils
dnf-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

dnf install sublime-text kernel-devel kernel-headers gcc make perl wget pigz -y

wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
exit 0
dnf -y install VirtualBox-6.1.x86_64

dnf-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf -y install vagrant

curl -O http://downloadfiles.idera.com/products/IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
dnf -y install ./IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.rpm
unzip IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip

yum install cloud-utils dos2unix -y
df
#growpart /dev/sda 1
#resize2fs /dev/sda1

cd vms 
sh init_vagrant.sh

sh start.sh
