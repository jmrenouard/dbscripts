#!/usr/bin/env python3

import sys
import argparse
from textwrap import dedent

# Configuration par défaut
defaults = {
    'mysql_dir': "/var/lib/mysql",
    'port': 3306,
    'log_error': "/var/log/mysql/mysqld.log",
    'log_bin_name': "mysqld-bin",
    'slow_query_log_file': "/var/log/mysql/slow_query.log",
    'socket_path': '/var/lib/mysql/mysql.sock',
    'pid_file': "mysqld.pid",
    'long_query_time': 30,
    'max_connections': 100,
    'server_id': 1,
    'bind_address': '0.0.0.0',
    'innodb_buffer_pool_size': '2G',
    'innodb_buffer_pool_chunk_size': '256M'
}


def generate_my_cnf(config):
    """
    Génère le fichier my.cnf à partir des paramètres fournis.
    """
    my_cnf = dedent("""
    [client]
    socket                         = {socket_path}

    [mysqld]
    # GENERAL #
    user                           = mysql
    default-storage-engine         = InnoDB
    socket                         = {socket_path}
    pid-file                       = {pid_file}
    
    # SAFETY #
    max-allowed-packet             = 16M
    max-connect-errors             = 1000000
    skip-name-resolve
    sysdate-is-now                 = 1
    innodb-strict-mode             = 1

    # DATA STORAGE #
    datadir                        = {mysql_dir}

    # SERVER ID #
    server-id                      = {server_id}
    report-host                    = server-{server_id}
    
    # BINARY LOGGING #
    log-bin                        = {log_bin_name}
    binlog_expire_logs_seconds     = 604800
    
    # CACHES AND LIMITS #
    max-connections                = {max_connections}
    tmp-table-size                 = 32M
    max-heap-table-size            = 32M
    thread-cache-size              = 50
    open-files-limit               = 17000
    table-definition-cache         = 400
    table-open-cache               = 128
    
    # INNODB #
    innodb-flush-method            = O_DIRECT
    innodb-redo-log-capacity       = 201326592
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = {innodb_buffer_pool_size}
    innodb-buffer-pool-chunk-size  = {innodb_buffer_pool_chunk_size}
    
    # LOGGING #
    log-error                      = {log_error}
    slow-query-log                 = 1
    slow-query-log-file            = {slow_query_log_file}
    log-queries-not-using-indexes  = ON
    long_query_time                = {long_query_time}
    bind-address                   = {bind_address}
    port                           = {port}
    performance_schema             = ON
    performance-schema-consumer-events-statements-history-long = ON
    performance-schema-consumer-events-statements-history = ON
    performance-schema-consumer-events-statements-current = ON
    performance-schema-consumer-events-stages-current = ON
    performance-schema-consumer-events-stages-history = ON
    performance-schema-consumer-events-stages-history-long = ON
    performance-schema-consumer-events-transactions-current = ON
    performance-schema-consumer-events-transactions-history = ON
    performance-schema-consumer-events-transactions-history-long = ON
    performance-schema-consumer-events-waits-current = ON
    performance-schema-consumer-events-waits-history = ON
    performance-schema-consumer-events-waits-history-long = ON
    performance-schema-instrument='%=ON'
    max-digest-length=2048
    performance-schema-max-digest-length=2048
    """).format(**config)
    print(my_cnf)


def main():
    parser = argparse.ArgumentParser(description="Generate my.cnf configuration file.")
    args = parser.parse_args()

    # Génération du fichier my.cnf
    generate_my_cnf(defaults)


if __name__ == "__main__":
    main()
