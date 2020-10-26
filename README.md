<<<<<<< HEAD
# Db Scripts
Training support
=======
# DB scripts #

## Setup VM Vagrant ##
```
# sudo sh installSoft.sh
# source profile
# vsetupVMs vstart
.... Take a long time ....
```

## Check Vagrant VMs ##
    # vlist

## Adding utils.sh on all VM servers ##
    # vssh_copy mariadb1,mariadb2,mariadb3,mariadb4,haproxy1 ./scripts/utils.sh /etc/profile.d/utils.sh
    # vssh_copy mariadb1,mariadb2,mariadb3,mariadb4,haproxy1 ./scripts/bin /opt/local root 755

## Running abritary command ##
    # vssh_cmd mariadb1,mariadb2,mariadb3,mariadb4 "hostname -s" silent
    # vssh_cmd haproxy1 "hostname -s"

## Executing remotly a script ##
    # vssh_exec mariadb1,mariadb2,mariadb3,mariadb4 scripts/1_system/2_s silent
    # vssh_cmd haproxy1 "hostname -s"

# Support dbscripts  #
## Bugs report ##
  [https://github.com/jmrenouard/dbscripts/issues](https://github.com/jmrenouard/dbscripts/issues "Fill an issue")

## Pull request ##
  [https://github.com/jmrenouard/dbscripts/pulls](https://github.com/jmrenouard/dbscripts/pulls "Pull Request")

## Send an email ##
  jmrenouard@gmail.com
