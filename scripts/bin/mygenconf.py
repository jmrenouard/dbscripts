#!/usr/bin/env python3

import sys
import math
import random
from textwrap import dedent

defaults = {
    'mysql_dir' : "/var/lib/mysql",
    'port' : 3306,
    'log_error' : "/var/log/mysql/mysqld.log",
    'log_bin_name' : "mysqld-bin",
    'slow_query_log_file' : "/var/log/mysql/slow_query.log",
    'socket_path': '/var/lib/mysql/mysql.sock',
    'pid_file' : "mysqld.pid",


    'mysql_ram_gb' : 1,

    'query_cache_type' : 0,
    'query_cache_size' : 0,

    'long_query_time' : 30,
    'max_connections' : 100,

    'server_id' : 1,
    'bind_address' : '0.0.0.0',
    'innodb_buffer_pool_chunk_size' : 134217728
}


def output_my_cnf(_metaconf):
    print(dedent("""
    [client]
    socket                         = {socket_path}

    [mysqld]
    # GENERAL #
    user                           = mysql
    default-storage-engine         = InnoDB
    socket                         = {socket_path}
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
    report-host                    = server-{server_id}
    # BINARY LOGGING #
    log-bin                        = {log_bin_name}
    expire-logs-days               = 7
    # CACHES AND LIMITS #
    max-connections                = {max_connections}
    tmp-table-size                 = 32M
    max-heap-table-size            = 32M
    query-cache-type               = {query_cache_type}
    query-cache-size               = {query_cache_size}
    thread-cache-size              = 50
    open-files-limit               = 16000

    table-definition-cache         = 400
    table-open-cache               = 128
    # INNODB #
    innodb-flush-method            = O_DIRECT
    innodb-defragment			   = 1

    # DePRECATED IN MARIADB 10.5
    # innodb-log-files-in-group    = 2
    ignore-db-dir                  =lost+found
    innodb-log-file-size           = {innodb_log_file_size}
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = {innodb_buffer_pool_size}
    innodb_buffer_pool_chunk_size  = {innodb_buffer_pool_chunk_size}
    # LOGGING #
    log-error                      = {log_error}
    slow-query-log                 = 1
    slow-query-log-file            = {slow_query_log_file}
    log-queries-not-using-indexes  = ON
    long_query_time                = {long_query_time}
    bind_address                   = {bind_address}
    port                           = {port}
    performance_schema             = ON
    performance-schema-consumer-events-statements-history-long = ON
    performance-schema-consumer-events-statements-history = ON
    performance-schema-consumer-events-statements-current = ON
    performance-schema-consumer-events-stages-current=ON
    performance-schema-consumer-events-stages-history=ON
    performance-schema-consumer-events-stages-history-long=ON
    performance-schema-consumer-events-transactions-current=ON
    performance-schema-consumer-events-transactions-history=ON
    performance-schema-consumer-events-transactions-history-long=ON
    performance-schema-consumer-events-waits-current=ON
    performance-schema-consumer-events-waits-history=ON
    performance-schema-consumer-events-waits-history-long=ON
    performance-schema-instrument='%=ON'
    max-digest-length=2048
    performance-schema-max-digest-length=2018

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

    return '96M'


def output_memory_gb(gb):

    if math.fabs(math.ceil(gb) - gb) < 0.01:
        return str(int(gb))+'G'

    return str(int(gb*1024))+'M'


def mycnf_make(m):
	# Pour X GO > 3Go 75 % de la RAM
	# 4 chunks par Go
    m['innodb_buffer_pool_size'] = output_memory_gb(float(m['mysql_ram_gb']) *  0.75)
    m['innodb_buffer_pool_chunk_size'] =int((float(m['mysql_ram_gb']) *  0.75 * 1024 * 1024* 1024) / (float(m['mysql_ram_gb']) * 4))

    # Pour 1 GO => 384M - 33%
    # 4 chunks
    if m['mysql_ram_gb'] == 1:
        m['innodb_buffer_pool_size'] = '384M'
        m['innodb_buffer_pool_chunk_size'] =384 * 1024 * 1024 / 4

    # Pour 2 GO => 1G - 50%
    # 8 chunks
    if m['mysql_ram_gb'] == 2:
        m['innodb_buffer_pool_size'] = '1G'
        m['innodb_buffer_pool_chunk_size'] =1024 * 1024* 1024 / 8

    # Pour 3 GO => 2G - 66%
    if m['mysql_ram_gb'] == 3:
        m['innodb_buffer_pool_size'] = '2G'
        m['innodb_buffer_pool_chunk_size'] =2 * 1024 * 1024* 1024 / 16

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