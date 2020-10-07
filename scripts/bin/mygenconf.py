#!/usr/bin/env python3

import sys
import math
import random
from textwrap import dedent

defaults = {
    'mysql_dir' : "/var/lib/mysql",

    'log_error' : "mysqld.log", 
    'slow_query_log_file' : "mysqld-slow.log", 
    
    'pid_file' : "/var/run/mysqld/mysqld.pid", 


    'mysql_ram_gb' : 1, 
    
    'query_cache_type' : 0, 
    'query_cache_size' : 0, 

    'long_query_time' : 2, 
    'max_connections' : 100, 

    'server_id' : 1,
    'bind_address' : '0.0.0.0'
}


def output_my_cnf(_metaconf): 
    print(dedent("""
    [mysqld]
    # GENERAL #
    user                           = mysql
    default-storage-engine         = InnoDB
    socket                         = {mysql_dir}/mysql.sock
    pid-file                       = {pid_file}
    # MyISAM #
    # key-buffer-size                = 32M
    # myisam-recover                 = FORCE,BACKUP
    # SAFETY #
    max-allowed-packet             = 16M
    max-connect-errors             = 1000000
    skip-name-resolve
    sql-mode                       = NO_ENGINE_SUBSTITUTION,NO_AUTO_CREATE_USER
    sysdate-is-now                 = 1
    innodb-strict-mode             = 1
    # DATA STORAGE #
    datadir                        = {mysql_dir}
    # SERVER ID # 
    server-id                      = {server_id}
    
    # BINARY LOGGING #
    log-bin
    # CACHES AND LIMITS #
    max-connections                = {max_connections}
    tmp-table-size                 = 32M
    max-heap-table-size            = 32M
    query-cache-type               = {query_cache_type}
    query-cache-size               = {query_cache_size}
    thread-cache-size              = 50
    open-files-limit               = 16300
    table-definition-cache         = 1024
    table-open-cache               = 2048
    # INNODB #
    innodb-flush-method            = O_DIRECT
    innodb-log-files-in-group      = 2
    innodb-log-file-size           = {innodb_log_file_size}
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = {innodb_buffer_pool_size}
    # LOGGING #
    log-error                      = {log_error}
    slow-query-log                 = 1
    slow-query-log-file            = {slow_query_log_file}
    log-queries-not-using-indexes  = OFF
    long_query_time                = 30
    bind_address                   = {bind_address}
    """.format(**mycnf_make(_metaconf))))
    
#    [mysql]
    # CLIENT #
#    port                           = 3306
#    socket                         = {mysql_dir}/mysql.sock
    
#    [mysqldump]
#    max-allowed-packet             = 16M
#    """.format(**mycnf_make(_metaconf))))

def mycnf_innodb_log_file_size_MB(innodb_buffer_pool_size_GB): 
    if int(innodb_buffer_pool_size_GB) > 64:
        return '768M'
    if int(innodb_buffer_pool_size_GB) > 24:
        return '512M'
    if int(innodb_buffer_pool_size_GB) > 8:
        return '256M'
    if int(innodb_buffer_pool_size_GB) > 2:
        return '128M'

    return '64M'


def output_memory_gb(gb): 

    if math.fabs(math.ceil(gb) - gb) < 0.01:
        return str(int(gb))+'G'

    return str(int(gb*1024))+'M'


def mycnf_make(m): 
    
    m['innodb_buffer_pool_size'] = output_memory_gb(float(m['mysql_ram_gb']) *  0.75) 
    m['innodb_log_file_size'] = mycnf_innodb_log_file_size_MB(m['mysql_ram_gb'])
    return m


def main(argv): 
    actual_conf = defaults
    for arg in argv: 
        kv = arg.split('=')
        if len(kv) == 2: 
            actual_conf[kv[0]] = kv[1]
                
    output_my_cnf(actual_conf)
    return 0


    
if __name__ == "__main__":
    sys.exit(main(sys.argv))