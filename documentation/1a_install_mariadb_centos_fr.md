# Opération Standard : Installation du serveur MariaDB 10.5 sur OS Centos

## Table des matières
- [Objectifs du document](#objectifs-du-document)
- [Procédure scriptées à distance via SSH](#procédure-scriptées-à-distance-via-ssh)
- [Exemple de procédure à distance par script](#exemple-de-procédure-à-distance-par-script)

## Objectifs du document

>  * Installation des packages logiciels pour MariaDB
>  * Installation des logiciels tiers relatif aux bases de données
>  * Installation des dernières versions logicielles
## Procédure scriptées à distance via SSH
| Etape | Description | Utilisateur | Commande |
| --- | --- | --- | --- |
| 1 | Load utilities functions  | root | # source profile |
| 2 | Execute generic script remotly  | root | # vssh_exec dbsrv1 ../scripts/2_install/1a_install_mariadb_centos.sh |
| 3 | Vérifier le code retour  | root | echo 0 (0) |

##  Exemple de procédure à distance par script
```bash
# vssh_exec dbsrv1 ../scripts/2_install/1a_install_mariadb_centos.sh
2021-05-26 22:14:03 CEST(DESKTOP-JPKE7F3) RUNNING SCRIPT 1a_install_mariadb_centos.sh ON dbsrv1(192.168.33.191) SERVER
2021-05-26 22:14:03 CEST(DESKTOP-JPKE7F3) _____________________________________________________________________________
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) START: BEGIN SCRIPT: INLINE SHELL
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) INFO:  run as root@dbsrv1
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) RUNNING COMMAND: rm -f /etc/yum.repos.d/mariadb_*.repo
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:14:04 CEST(dbsrv1) INFO: [SUCCESS]  rm -f /etc/yum.repos.d/mariadb_*.repo  [SUCCESS]
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) INFO: SETUP mariadb_10.5.repo FILE
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) RUNNING COMMAND: cat /etc/yum.repos.d/mariadb_10.5.repo
# MariaDB 10.5 CentOS repository list - created Wed May 26 22:14:04 CEST 2021
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB_10.5
baseurl = http://yum.mariadb.org/10.5/centos8-amd64
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:14:04 CEST(dbsrv1) INFO: [SUCCESS]  cat /etc/yum.repos.d/mariadb_10.5.repo  [SUCCESS]
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) RUNNING COMMAND: yum -y remove mysql-server mariadb-server
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
No match for argument: mysql-server
No match for argument: mariadb-server
Dependencies resolved.
Nothing to do.
Complete!
No packages marked for removal.
2021-05-26 22:14:04 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:14:04 CEST(dbsrv1) INFO: [SUCCESS]  yum -y remove mysql-server mariadb-server  [SUCCESS]
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:04 CEST(dbsrv1) RUNNING COMMAND: yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
2021-05-26 22:14:04 CEST(dbsrv1) -----------------------------------------------------------------------------
MariaDB_10.5                                     11 kB/s | 3.4 kB     00:00    
epel-release-latest-8.noarch.rpm                 33 kB/s |  22 kB     00:00    
Package epel-release-8-10.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-26 22:14:06 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:14:06 CEST(dbsrv1) INFO: [SUCCESS]  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  [SUCCESS]
2021-05-26 22:14:06 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:06 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:14:06 CEST(dbsrv1) RUNNING COMMAND: yum -y install python3 MariaDB-server MariaDB-backup MariaDB-client MariaDB-compat MariaDB-cracklib-password-check MariaDB-connect-engine
2021-05-26 22:14:06 CEST(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 0:00:02 ago on Wed 26 May 2021 10:14:05 PM CEST.
Package python36-3.6.8-2.module_el8.3.0+562+e162826a.x86_64 is already installed.
Package MariaDB-backup-10.5.10-1.el8.x86_64 is already installed.
Package MariaDB-client-10.5.10-1.el8.x86_64 is already installed.
Package MariaDB-compat-10.5.10-1.el8.x86_64 is already installed.
Dependencies resolved.
================================================================================
 Package                           Arch     Version           Repository   Size
================================================================================
Installing:
 MariaDB-connect-engine            x86_64   10.5.10-1.el8     mariadb     622 k
 MariaDB-cracklib-password-check   x86_64   10.5.10-1.el8     mariadb      12 k
 MariaDB-server                    x86_64   10.5.10-1.el8     mariadb      27 M
Installing dependencies:
 boost-program-options             x86_64   1.66.0-10.el8     appstream   141 k
 galera-4                          x86_64   26.4.8-1.el8      mariadb      13 M
 libtool-ltdl                      x86_64   2.4.6-25.el8      baseos       58 k
 lsof                              x86_64   4.93.2-1.el8      baseos      253 k
 unixODBC                          x86_64   2.3.7-1.el8       appstream   458 k

Transaction Summary
================================================================================
Install  8 Packages

Total size: 41 M
Total download size: 27 M
Installed size: 192 M
Downloading Packages:
[SKIPPED] boost-program-options-1.66.0-10.el8.x86_64.rpm: Already downloaded   
[SKIPPED] unixODBC-2.3.7-1.el8.x86_64.rpm: Already downloaded                  
[SKIPPED] libtool-ltdl-2.4.6-25.el8.x86_64.rpm: Already downloaded             
[SKIPPED] lsof-4.93.2-1.el8.x86_64.rpm: Already downloaded                     
[SKIPPED] MariaDB-connect-engine-10.5.10-1.el8.x86_64.rpm: Already downloaded  
[SKIPPED] MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64.rpm: Already downloaded
[SKIPPED] galera-4-26.4.8-1.el8.x86_64.rpm: Already downloaded                 
[MIRROR] MariaDB-server-10.5.10-1.el8.x86_64.rpm: Interrupted by header callback: Server reports Content-Length: 16302784 but expected size is: 28029632
(8/8): MariaDB-server-10.5.10-1.el8.x86_64.rpm  787 kB/s |  27 MB     00:34    
--------------------------------------------------------------------------------
Total                                           786 kB/s |  27 MB     00:34     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Installing       : lsof-4.93.2-1.el8.x86_64                               1/8 
  Installing       : libtool-ltdl-2.4.6-25.el8.x86_64                       2/8 
  Running scriptlet: libtool-ltdl-2.4.6-25.el8.x86_64                       2/8 
  Installing       : unixODBC-2.3.7-1.el8.x86_64                            3/8 
  Running scriptlet: unixODBC-2.3.7-1.el8.x86_64                            3/8 
  Installing       : boost-program-options-1.66.0-10.el8.x86_64             4/8 
  Running scriptlet: boost-program-options-1.66.0-10.el8.x86_64             4/8 
  Running scriptlet: galera-4-26.4.8-1.el8.x86_64                           5/8 
  Installing       : galera-4-26.4.8-1.el8.x86_64                           5/8 
  Running scriptlet: galera-4-26.4.8-1.el8.x86_64                           5/8 
  Running scriptlet: MariaDB-server-10.5.10-1.el8.x86_64                    6/8 
  Installing       : MariaDB-server-10.5.10-1.el8.x86_64                    6/8 
  Running scriptlet: MariaDB-server-10.5.10-1.el8.x86_64                    6/8 
  Running scriptlet: MariaDB-connect-engine-10.5.10-1.el8.x86_64            7/8 
  Installing       : MariaDB-connect-engine-10.5.10-1.el8.x86_64            7/8 
  Running scriptlet: MariaDB-connect-engine-10.5.10-1.el8.x86_64            7/8 
  Running scriptlet: MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64   8/8 
  Installing       : MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64   8/8 
  Running scriptlet: MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64   8/8 
  Running scriptlet: MariaDB-server-10.5.10-1.el8.x86_64                    8/8 
/var/tmp/rpm-tmp.d6jmZl: line 6: [: is-active: binary operator expected

  Running scriptlet: MariaDB-connect-engine-10.5.10-1.el8.x86_64            8/8 
  Running scriptlet: MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64   8/8 
  Verifying        : boost-program-options-1.66.0-10.el8.x86_64             1/8 
  Verifying        : unixODBC-2.3.7-1.el8.x86_64                            2/8 
  Verifying        : libtool-ltdl-2.4.6-25.el8.x86_64                       3/8 
  Verifying        : lsof-4.93.2-1.el8.x86_64                               4/8 
  Verifying        : MariaDB-connect-engine-10.5.10-1.el8.x86_64            5/8 
  Verifying        : MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64   6/8 
  Verifying        : MariaDB-server-10.5.10-1.el8.x86_64                    7/8 
  Verifying        : galera-4-26.4.8-1.el8.x86_64                           8/8 

Installed:
  MariaDB-connect-engine-10.5.10-1.el8.x86_64                                   
  MariaDB-cracklib-password-check-10.5.10-1.el8.x86_64                          
  MariaDB-server-10.5.10-1.el8.x86_64                                           
  boost-program-options-1.66.0-10.el8.x86_64                                    
  galera-4-26.4.8-1.el8.x86_64                                                  
  libtool-ltdl-2.4.6-25.el8.x86_64                                              
  lsof-4.93.2-1.el8.x86_64                                                      
  unixODBC-2.3.7-1.el8.x86_64                                                   

Complete!
2021-05-26 22:15:18 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:15:18 CEST(dbsrv1) INFO: [SUCCESS]  yum -y install python3 MariaDB-server MariaDB-backup MariaDB-client MariaDB-compat MariaDB-cracklib-password-check MariaDB-connect-engine  [SUCCESS]
2021-05-26 22:15:18 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:18 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:18 CEST(dbsrv1) RUNNING COMMAND: yum -y install cracklib cracklib-dicts tree socat jemalloc rsync nmap lsof perl-DBI nc mariadb-server-utils pigz perl-DBD-MySQL git pwgen
2021-05-26 22:15:18 CEST(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 0:01:17 ago on Wed 26 May 2021 10:14:05 PM CEST.
Package cracklib-2.9.6-15.el8.x86_64 is already installed.
Package cracklib-dicts-2.9.6-15.el8.x86_64 is already installed.
Package tree-1.7.0-15.el8.x86_64 is already installed.
Package socat-1.7.3.3-2.el8.x86_64 is already installed.
Package jemalloc-5.2.1-2.el8.x86_64 is already installed.
Package rsync-3.1.3-9.el8.x86_64 is already installed.
Package nmap-2:7.70-5.el8.x86_64 is already installed.
Package lsof-4.93.2-1.el8.x86_64 is already installed.
Package perl-DBI-1.641-3.module_el8.1.0+199+8f0a6bbd.x86_64 is already installed.
Package nmap-ncat-2:7.70-5.el8.x86_64 is already installed.
Package MariaDB-server-10.5.10-1.el8.x86_64 is already installed.
Package pigz-2.4-4.el8.x86_64 is already installed.
Package perl-DBD-MySQL-4.046-3.module_el8.1.0+203+e45423dc.x86_64 is already installed.
Package git-2.27.0-1.el8.x86_64 is already installed.
Package pwgen-2.08-3.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-26 22:15:24 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:15:24 CEST(dbsrv1) INFO: [SUCCESS]  yum -y install cracklib cracklib-dicts tree socat jemalloc rsync nmap lsof perl-DBI nc mariadb-server-utils pigz perl-DBD-MySQL git pwgen  [SUCCESS]
2021-05-26 22:15:24 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:24 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:24 CEST(dbsrv1) RUNNING COMMAND: yum -y install https://repo.percona.com/yum/release/8/RPMS/x86_64/percona-toolkit-3.2.1-1.el8.x86_64.rpm
2021-05-26 22:15:24 CEST(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 0:01:19 ago on Wed 26 May 2021 10:14:05 PM CEST.
percona-toolkit-3.2.1-1.el8.x86_64.rpm          1.1 MB/s |  14 MB     00:12    
Package percona-toolkit-3.2.1-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-26 22:15:37 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:15:37 CEST(dbsrv1) INFO: [SUCCESS]  yum -y install https://repo.percona.com/yum/release/8/RPMS/x86_64/percona-toolkit-3.2.1-1.el8.x86_64.rpm  [SUCCESS]
2021-05-26 22:15:37 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:37 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:37 CEST(dbsrv1) RUNNING COMMAND: pip3 install mycli
2021-05-26 22:15:37 CEST(dbsrv1) -----------------------------------------------------------------------------
WARNING: Running pip install with root privileges is generally not a good idea. Try `pip3 install --user` instead.
Collecting mycli
  Using cached https://files.pythonhosted.org/packages/05/06/bacbbbf35f770d8fd07725f56a6b3eeb02f99a0ae1b6f0468c6f88fd0c02/mycli-1.24.1-py2.py3-none-any.whl
Collecting cli-helpers[styles]>=2.0.1 (from mycli)
  Using cached https://files.pythonhosted.org/packages/3d/fb/77b7e149d8d7197cdec71413fe60a7f870d69fa77d659d7cb0ebaa221276/cli_helpers-2.1.0-py3-none-any.whl
Collecting importlib-resources>=5.0.0 (from mycli)
  Using cached https://files.pythonhosted.org/packages/a4/30/b230b6586bcf6b80752ae42979f3b0da70bbde977d2b73eafd20c693b3db/importlib_resources-5.1.4-py3-none-any.whl
Collecting click>=7.0 (from mycli)
  Downloading https://files.pythonhosted.org/packages/76/0a/b6c5f311e32aeb3b406e03c079ade51e905ea630fc19d1262a46249c1c86/click-8.0.1-py3-none-any.whl (97kB)
Collecting prompt-toolkit<4.0.0,>=3.0.6 (from mycli)
  Using cached https://files.pythonhosted.org/packages/eb/e6/4b4ca4fa94462d4560ba2f4e62e62108ab07be2e16a92e594e43b12d3300/prompt_toolkit-3.0.18-py3-none-any.whl
Collecting Pygments>=1.6 (from mycli)
  Downloading https://files.pythonhosted.org/packages/a6/c9/be11fce9810793676017f79ffab3c6cb18575844a6c7b8d4ed92f95de604/Pygments-2.9.0-py3-none-any.whl (1.0MB)
Collecting cryptography>=1.0.0 (from mycli)
  Using cached https://files.pythonhosted.org/packages/9b/77/461087a514d2e8ece1c975d8216bc03f7048e6090c5166bc34115afdaa53/cryptography-3.4.7.tar.gz
    Complete output from command python setup.py egg_info:
    
            =============================DEBUG ASSISTANCE==========================
            If you are seeing an error here please try the following to
            successfully install cryptography:
    
            Upgrade to the latest pip and try again. This will fix errors for most
            users. See: https://pip.pypa.io/en/stable/installing/#upgrading-pip
            =============================DEBUG ASSISTANCE==========================
    
    Traceback (most recent call last):
      File "<string>", line 1, in <module>
      File "/tmp/pip-build-gzkicfq2/cryptography/setup.py", line 14, in <module>
        from setuptools_rust import RustExtension
    ModuleNotFoundError: No module named 'setuptools_rust'
    
    ----------------------------------------
Command "python setup.py egg_info" failed with error code 1 in /tmp/pip-build-gzkicfq2/cryptography/
2021-05-26 22:15:42 CEST(dbsrv1) INFO: RETURN CODE: 1
2021-05-26 22:15:42 CEST(dbsrv1) ERROR: pip3 install mycli
2021-05-26 22:15:42 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:42 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:42 CEST(dbsrv1) RUNNING COMMAND: yum -y install https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm
2021-05-26 22:15:42 CEST(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 0:01:37 ago on Wed 26 May 2021 10:14:05 PM CEST.
[MIRROR] mysqlreport-3.5-23.fc33.noarch.rpm: Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
[MIRROR] mysqlreport-3.5-23.fc33.noarch.rpm: Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
[MIRROR] mysqlreport-3.5-23.fc33.noarch.rpm: Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
[MIRROR] mysqlreport-3.5-23.fc33.noarch.rpm: Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
[FAILED] mysqlreport-3.5-23.fc33.noarch.rpm: Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
Status code: 404 for https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm (IP: 195.220.108.108)
2021-05-26 22:15:43 CEST(dbsrv1) INFO: RETURN CODE: 1
2021-05-26 22:15:43 CEST(dbsrv1) ERROR: yum -y install https://rpmfind.net/linux/fedora-secondary/development/rawhide/Everything/s390x/os/Packages/m/mysqlreport-3.5-23.fc33.noarch.rpm
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:43 CEST(dbsrv1) RUNNING COMMAND: rm -rf /opt/local/MySQLTuner-perl
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:43 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:15:43 CEST(dbsrv1) INFO: [SUCCESS]  rm -rf /opt/local/MySQLTuner-perl  [SUCCESS]
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:15:43 CEST(dbsrv1) RUNNING COMMAND: git clone https://github.com/major/MySQLTuner-perl.git
2021-05-26 22:15:43 CEST(dbsrv1) -----------------------------------------------------------------------------
Cloning into 'MySQLTuner-perl'...
2021-05-26 22:16:12 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:16:12 CEST(dbsrv1) INFO: [SUCCESS]  git clone https://github.com/major/MySQLTuner-perl.git  [SUCCESS]
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:12 CEST(dbsrv1) RUNNING COMMAND: chmod 755 /opt/local/MySQLTuner-perl/mysqltuner.pl
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:12 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:16:12 CEST(dbsrv1) INFO: [SUCCESS]  chmod 755 /opt/local/MySQLTuner-perl/mysqltuner.pl  [SUCCESS]
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:12 CEST(dbsrv1) RUNNING COMMAND: yum -y install perl-App-cpanminus
2021-05-26 22:16:12 CEST(dbsrv1) -----------------------------------------------------------------------------
Last metadata expiration check: 0:02:08 ago on Wed 26 May 2021 10:14:05 PM CEST.
Package perl-App-cpanminus-1.7044-5.module_el8.3.0+445+46ff4549.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
2021-05-26 22:16:13 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:16:13 CEST(dbsrv1) INFO: [SUCCESS]  yum -y install perl-App-cpanminus  [SUCCESS]
2021-05-26 22:16:13 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:13 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:13 CEST(dbsrv1) RUNNING COMMAND: cpanm MySQL::Diff
2021-05-26 22:16:13 CEST(dbsrv1) -----------------------------------------------------------------------------
MySQL::Diff is up to date. (0.60)
2021-05-26 22:16:14 CEST(dbsrv1) INFO: RETURN CODE: 0
2021-05-26 22:16:14 CEST(dbsrv1) INFO: [SUCCESS]  cpanm MySQL::Diff  [SUCCESS]
2021-05-26 22:16:14 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:14 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:14 CEST(dbsrv1) END: END SCRIPT: CentOS Linux ENDED WITH WARNING OR ERROR
2021-05-26 22:16:14 CEST(dbsrv1) -----------------------------------------------------------------------------
2021-05-26 22:16:14 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
2021-05-26 22:16:14 CEST(DESKTOP-JPKE7F3) END: RUNNING SCRIPT 1a_install_mariadb_centos.sh ON dbsrv1(192.168.33.191) SERVER ENDED SUCCESSFULLY
2021-05-26 22:16:14 CEST(DESKTOP-JPKE7F3) -----------------------------------------------------------------------------
# echo 0
0

```

