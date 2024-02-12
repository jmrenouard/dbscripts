#!/bin/bash
source bashrc

asetdebug

if [ -z "$1" ] || [ "$1" = "prepare" ]; then
    echo "## Update system"
    apv ../ansible/update_apt_distribution.yaml

    echo "## Install Scripts"
    apv ../ansible/install_scripts.yaml
fi

if [ -z "$1" ] || [ "$1" = "system" ]; then
    echo "## Filtering network and process access"
    aexec mysql ../scripts/1_system/2_iptables.sh
    aexec mysql ../scripts/1_system/3b_selinux_enforcing.sh

    echo "## Security & Kernel parameters"
    aexec mysql ../scripts/1_system/4_security.sh
    aexec mysql ../scripts/1_system/5_sysctl.sh

    echo "## Tuned daemon for all vms"
    aexec all ../scripts/1_system/6_tuned.sh

    echo "## NTP synchronisation for all vms"
    aexec all ../scripts/1_system/7_ntp.sh
fi

if [ -z "$1" ] || [ "$1" = "mysql" ]; then
    echo "## Install MySQL on all db nodes"
    aexec mysql ../scripts/2_install/1b_install_mariadb_ubuntu.sh

    echo "## Pre tuning database"
    aexec mysql ../scripts/3_database/3_config_start.sh
fi

if [ -z "$1" ] || [ "$1" = "database" ]; then
    echo "## Removing test acccess staff"
    aexec mysql
     ../scripts/3_database/1_secure_access.sh

    echo "## Adding secure password"
    aexec mysql ../scripts/3_database/2_set_password.sh
fi

if [ -z "$1" ] || [ "$1" = "ssl" ]; then
    echo "## SSL server settings"
    #aexec mysql ../scripts/3_database/4a_server_ssl_access.sh
fi

if [ -z "$1" ] || [ "$1" = "datatest" ]; then
    echo "## Insert test data"
    aexec node1 ../scripts/3_database/3_sample_database.sh
fi

if [ -z "$1" ] || [ "$1" = "galera" ]; then
    echo "## Bootstrap node1 into Galera cluster"
    aexec node1 ../scripts/8_galera/5_bootstrap_node.sh

    echo "## Bootstrap node2 into Galera cluster"
    aexec node2 ../scripts/8_galera/6_start_new_node.sh

    echo "## Bootstrap node3 into Galera cluster"
    aexec node3 ../scripts/8_galera/6_start_new_node.sh
fi

if [ -z "$1" ] || [ "$1" = "maxscale" ]; then
    echo "## install maxscale on loadb1"
    aexec loadb1 ../scripts/10_proxy/13_maxscale.sh

    echo "## Install Mysql client on loadb1"
    aexec loadb1 ../scripts/2_install/1c_install_mariadb_client_ubuntu.sh

fi
