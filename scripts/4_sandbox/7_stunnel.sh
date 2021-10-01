#!/bin/bash

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

lRC=0

setup_ubuntu_nfs_server()
{
    apt -y install nfs-kernel-server nfswatch nfstrace quota stunnel4
}

setup_ubuntu_nfs_client()
{
    apt -y install nfs-common stunnel4
}

setup_centos_nfs_client()
{
    yum -y install nfs-utils stunnel
}

push_cert_config()
{
    local target=$1
    rsync -avz /etc/stunnel/*.pem $target:/etc/stunnel
}

gen_stunnel_cert()
{
    cd /etc/stunnel/
     rm stunnel.crt stunnel.key stunnel.pem stunnel.csr

    openssl req -newkey rsa:4096 -x509 -days 3650 -nodes \
  -out stunnel.pem -keyout stunnel.pem
  chmod 400 stunnel.pem

}

gen_stunnel_server_conf()
{
    echo "verify  =       4
CAfile  =       /etc/stunnel/stunnel.pem
cert    =       /etc/stunnel/stunnel.pem
pid = /var/run/stunnel.pid
output = /var/log/stunnel4/stunnel.log

[nfs_over_stunnel]
accept = 0.0.0.0:2450
connect = 127.0.0.1:2049" > /etc/stunnel/stunnel.conf
chmod 644 /etc/stunnel/stunnel.conf
systemctl restart stunnel4
systemctl status stunnel4
systemctl enable stunnel4
}

gen_stunnel_client_conf()
{
    local srv=$1
    echo "verify  =       4
CAfile  =       /etc/stunnel/stunnel.pem
cert    =       /etc/stunnel/stunnel.pem
pid = /var/run/stunnel.pid
output = /var/log/stunnel4/stunnel.log
client = yes
[nfs_over_stunnel]
accept = 127.0.0.1:2049
connect = ${srv}:2450
" > /etc/stunnel/stunnel.conf
chmod 644 /etc/stunnel/stunnel.conf
systemctl restart stunnel4
systemctl status stunnel4
systemctl enable stunnel4
}