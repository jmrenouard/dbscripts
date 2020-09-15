#!/bin/sh

rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
rpm -v --import https://www.virtualbox.org/download/oracle_vbox.asc

yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

yum install sublime-text kernel-devel kernel-headers gcc make perl wget -y

wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo

yum -y install VirtualBox-6.1.x86_64
yum -y install https://releases.hashicorp.com/vagrant/2.2.10/vagrant_2.2.10_x86_64.rpm