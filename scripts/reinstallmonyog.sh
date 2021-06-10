#!/bin/bash

sudo rpm -e IderaSQLdmforMySQL-8.9.2-0.x86_64
sudo rpm -e IderaSQLdmforMySQL-8.9.2-0.x86_64
sudo rm -rf /etc/init.d/MONyogd /usr/local/MONyog/

sudo yum -y install $HOME/Downloads/Idera*.rpm
