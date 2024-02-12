https://dd4t.dadesktop.com

https://dd4t.dadesktop.com/da/join/eb6809

https://github.com/jmrenouard/dbscripts/

```bash
git pull

chmod 600 vms/id_rsa

vupdateScript
vssh_cmd $all_vms "ip a"
echo $all_vms

vlist
```

# Préparation
```bash
vssh_exec $all_vms scripts/1_system/1_update.sh
vssh_cmd $all_vms "reboot"

vssh_exec $all_vms scripts/1_system/2_iptables.sh
vssh_exec $all_vms scripts/1_system/3_selinux.sh
vssh_exec $all_vms scripts/1_system/4_security.sh
vssh_exec $all_vms scripts/1_system/5_sysctl.sh
vssh_exec $all_vms scripts/1_system/6_tuned.sh
vssh_exec $all_vms scripts/1_system/7_ntp.sh
```

# Installation

```bash
vssh_exec $db_vms scripts/2_install/1a_install_mariadb_centos.sh
```

# Paramétrage MariaDB

```bash
vssh_exec $db_vms scripts/2_install/3_config_start.sh
```

# Sécurisation et données

```bash
vssh_exec dbsrv1 scripts/3_database/1_secure_access.sh
vssh_exec dbsrv1 scripts/3_database/2_set_password.sh
vssh_exec dbsrv1 scripts/3_database/3_sample_database.sh
```

# Bootstrap cluster
```bash
vssh_exec dbsrv1 scripts/8_galera/5_bootstrap_node.sh
```

# Ajout des 2 autres noeuds

```bash
vssh_exec dbsrv2,dbsrv3 scripts/8_galera/6_start_new_node.sh
```



grant all on sbtest.* to 'sbtest'@'localhost';