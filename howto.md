# Setup multiple VMS with virtualBox and Vagrant #

## Update Centos Like OS ##

```
$ sudo yum -y update 
...
```


## Download dbscripts ##

```
$ git clone https://github.com/jmrenouard/dbscripts.git
Cloning into 'dbscripts'...
remote: Enumerating objects: 1638, done.
remote: Counting objects: 100% (474/474), done.
remote: Compressing objects: 100% (329/329), done.
remote: Total 1638 (delta 276), reused 271 (delta 142), pack-reused 1164
Receiving objects: 100% (1638/1638), 375.57 KiB | 0 bytes/s, done.
Resolving deltas: 100% (1076/1076), done.
```


## Starting installSoft.sh ##

```
$ cd dbscripts
$ sudo sh ./installSoft.sh 
Loaded plugins: fastestmirror
...
```


## Checking installSoft.sh ##

```
$ sudo sh ./installSoft.sh check
sublime-text-3211-1.x86_64
IderaSQLdmforMySQL-8.9.2-0.x86_64
vagrant-2.2.13-1.x86_64
VirtualBox-6.1-6.1.22_144080_el7-1.x86_64
```


## Installing vagrant plugins ##

```
$ cd vms
$ sudo sh init_vagrant.sh 
Installing the 'vagrant-vbguest' plugin. This can take a few minutes...
Fetching micromachine-3.0.0.gem
Fetching vagrant-vbguest-0.29.0.gem
Installed the plugin 'vagrant-vbguest (0.29.0)'!
Installing the 'vagrant-hostmanager' plugin. This can take a few minutes...
Fetching vagrant-hostmanager-1.8.9.gem
Installed the plugin 'vagrant-hostmanager (1.8.9)'!
Installing the 'vagrant-persistent-storage' plugin. This can take a few minutes...
Fetching vagrant-persistent-storage-0.0.49.gem
Installed the plugin 'vagrant-persistent-storage (0.0.49)'!
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.ratiokontakt.de
 * epel: mirror.digitalnova.at
 * extras: mirror.cuegee.com
 * updates: centos.mirror.iphh.net
Package kernel-devel-3.10.0-1160.25.1.el7.x86_64 already installed and latest version
Resolving Dependencies
--> Running transaction check
---> Package dkms.noarch 0:2.8.4-1.el7 will be installed
--> Processing Dependency: elfutils-libelf-devel for package: dkms-2.8.4-1.el7.noarch
--> Running transaction check
---> Package elfutils-libelf-devel.x86_64 0:0.176-5.el7 will be installed
--> Finished Dependency Resolution
...
```

