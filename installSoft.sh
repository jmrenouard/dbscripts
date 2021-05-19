#!/bin/sh


if [ "$1" = "check" ]; then
	rpm -qa | grep -Ei '(vagrant|virtualbox|iderasql|sublime|oracle)'
	exit 0
fi


rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
rpm -v --import https://www.virtualbox.org/download/oracle_vbox.asc

yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

yum install sublime-text kernel-devel kernel-headers gcc make perl wget -y

wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo

yum -y install VirtualBox-6.1.x86_64
yum -y install https://releases.hashicorp.com/vagrant/2.2.16/vagrant_2.2.16_x86_64.rpm

curl -O http://downloadfiles.idera.com/products/IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
yum -y install ./IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.rpm
unzip IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip

yum install cloud-utils -y
df
#growpart /dev/sda 1
#resize2fs /dev/sda1

cd vms 
sh init_vagrant.sh

sh start.sh
