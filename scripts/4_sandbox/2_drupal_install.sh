#!/bin/bash

source /etc/os-release

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    eval "$tcmd"
    local cRC=$?
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

_NAME="$(basename "$(readlink -f "$0")")"
NAME="${_NAME}"
my_private_ipv4=$(ip a | grep inet | grep 'brd' | grep -E '(192.168|172.2)'| cut -d/ -f1 | awk '{print $2}'|head -n1)
my_private_ip="${my_private_ipv4}"

DRUPAL_VERSION="8.9.9"
lRC=0

banner "BEGIN SCRIPT: ${_NAME}"

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
set -x
tar xf drupal-${DRUPAL_VERSION}.tar.gz
[ -d "/var/www/html/drupal" ] && rm -rf /var/www/html/drupal
mv drupal-${DRUPAL_VERSION} /var/www/html/drupal

mkdir /var/www/html/drupal/sites/default/files
cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php

semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/drupal(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/drupal/sites/default/settings.php'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/drupal/sites/default/files'
restorecon -Rv /var/www/html/drupal
restorecon -v /var/www/html/drupal/sites/default/settings.php
restorecon -Rv /var/www/html/drupal/sites/default/files

chown -R apache:apache /var/www/html/drupal
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

footer "END SCRIPT: ${_NAME}"
exit $lRC
