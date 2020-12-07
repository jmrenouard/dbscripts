#!/usr/bin/env python3

import sys
import math
import random
from textwrap import dedent

defaults = {
    'mysql_dir' : "/var/lib/mysql",

    'log_error' : "mysqld.log",
    'log_bin_name' : "mysqld-bin",
    'slow_query_log_file' : "mysqld-slow.log",

    'pid_file' : "mysqld.pid",


    'mysql_ram_gb' : 1,

    'query_cache_type' : 0,
    'query_cache_size' : 0,

    'long_query_time' : 30,
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
    report-host                    = server-{server_id}
    # BINARY LOGGING #
    log-bin                        = {log_bin_name}

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

    # DePRECATED IN MARIADB 10.5
    # innodb-log-files-in-group      = 2

    innodb-log-file-size           = {innodb_log_file_size}
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = {innodb_buffer_pool_size}
    # LOGGING #
    log-error                      = {log_error}
    slow-query-log                 = 1
    slow-query-log-file            = {slow_query_log_file}
    log-queries-not-using-indexes  = ON
    long_query_time                = {long_query_time}
    bind_address                   = {bind_address}

    performance_schema=ON
    performance_schema_max_cond_classes     =80
    performance_schema_max_file_classes     =50
    performance_schema_max_mutex_classes    =200
    performance_schema_max_rwlock_classes   =40
    performance_schema_max_socket_classes   =10
    performance_schema_max_stage_classes    =150
    performance_schema_max_statement_classes=168
    performance_schema_max_thread_classes   =50

    performance_schema_accounts_size=100
    performance_schema_hosts_size   =100
    performance_schema_users_size   =100
    performance_schema_events_stages_history_long_size    =1000
    performance_schema_events_stages_history_size         =10
    performance_schema_events_statements_history_long_size=1000
    performance_schema_events_statements_history_size     =10
    performance_schema_events_waits_history_long_size     =10000
    performance_schema_events_waits_history_size          =10

    performance_schema_max_cond_instances   =1258
    performance_schema_max_file_handles     =32768
    performance_schema_max_file_instances   =6250
    performance_schema_max_mutex_instances  =5133
    performance_schema_max_rwlock_instances =2765
    performance_schema_max_table_handles    =366
    performance_schema_max_table_instances  =587
    performance_schema_max_socket_instances =230
    performance_schema_max_thread_instances =288
    performance_schema_setup_actors_size =100
    performance_schema_setup_objects_size=100

    performance_schema_session_connect_attrs_size=512
    performance_schema_digests_size              =200
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

    m['innodb_buffer_pool_size'] = output_memory_gb(float(m['mysql_ram_gb']) *  0.75)
    if m['mysql_ram_gb'] == 1:
        m['innodb_buffer_pool_size'] = '384M'
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