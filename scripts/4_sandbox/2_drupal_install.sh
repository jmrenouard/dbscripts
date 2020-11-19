#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

DRUPAL_VERSION="8.9.9"
lRC=0

banner "BEGIN SCRIPT: $_NAME"

dnf install -y @php
dnf install -y php php-{cli,mysqlnd,json,opcache,xml,mbstring,gd,curl}
systemctl enable --now php-fpm
systemctl status php-fpm

dnf install -y @httpd
systemctl enable --now httpd

firewall-cmd --add-service={http,https} --permanent
firewall-cmd --reload

cd /data/
dnf -y install wget
wget https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz
tar xvf drupal-${DRUPAL_VERSION}.tar.gz
mv drupal-${DRUPAL_VERSION} /var/www/html/drupal

mkdir /var/www/html/drupal/sites/default/files
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php

semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/drupal(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/drupal/sites/default/settings.php'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/drupal/sites/default/files'
restorecon -Rv /var/www/html/drupal
restorecon -v /var/www/html/drupal/sites/default/settings.php
restorecon -Rv /var/www/html/drupal/sites/default/files

chown -R apache:apache  /var/www/html/drupal
(
	cat <<"EndOfConf"
	<VirtualHost *:80>
    ServerAdmin webmaster@example.com
    ServerName ${my_private_ip}
    DocumentRoot /var/www/html/drupal
    <Directory /var/www/html/drupal/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/drupal_error.log
    CustomLog /var/log/httpd/drupal_access.log combined
</VirtualHost>
EndOfConf
) | tee /etc/httpd/conf.d/drupal.conf
chmod 755 /etc/httpd/conf.d/drupal.conf
systemctl restart httpd

footer "BEGIN SCRIPT: $_NAME"
