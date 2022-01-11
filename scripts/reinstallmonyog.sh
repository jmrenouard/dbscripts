#!/bin/bash

yum -y remove IderaSQLdmforMySQL
rm -rf /etc/init.d/MONyogd /usr/local/MONyog/

curl -O https://downloadfiles.idera.com/products/IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
unzip IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.zip
yum -y install IderaSQLDiagnosticManagerForMySQL-Linux-x64-rpm.rpm

systemctl restart MONyogd
