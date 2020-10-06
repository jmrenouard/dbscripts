#!/usr/bin/env python3

import os
import sys
import logging
import logging.handlers
import shell

# Some var
_scriptname = os.path.basename(sys.argv[0])
_scriptdir = os.path.abspath(os.path.dirname(sys.argv[0]))
_logformat = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
global log


def init_logger(debug=True):
    # init logging
    global log
    formatter = logging.Formatter(_logformat)
    log = logging.getLogger(_scriptname)

    # init log file log
    logfile = "%s/%s.log" % (_scriptdir, _scriptname)
    fileHandler = logging.handlers.RotatingFileHandler(
        logfile, maxBytes=(1048576*5), backupCount=7
    )
    fileHandler.setFormatter(formatter)
    fileHandler.setLevel(logging.DEBUG)
    log.addHandler(fileHandler)

    # init console log
    consoleHandler = logging.StreamHandler(sys.stdout)
    consoleHandler.setFormatter(formatter)
    if debug is True:
        log.setLevel(logging.DEBUG)
    else:
        log.setLevel(logging.INFO)
    log.addHandler(consoleHandler)
    return log


def exec_shell(cmd):
    global log

    log.debug("RUNNING SHELL: %s" % cmd)
    print('\n'.join(shell.shell(cmd).output()))


def debug_args(p):
    global log
    log.debug(p.parse_args())
    log.debug("----------")
    log.debug(p.format_help())
    log.debug("----------")
    log.debug(p.format_values())
