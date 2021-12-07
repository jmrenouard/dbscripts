#!/bin/bash

rpm -qa | grep -i idera| xargs -n1 rpm -e IderaSQLdmforMySQL-8.9.2-0.x86_64
rm -rf /etc/init.d/MONyogd /usr/local/MONyog/

curl https://downloadfiles.idera.com/products/IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
unzip IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
yum -y install IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.rpm
