#!/usr/bin/env python3

import utils
import configargparse

# init args and config
p = configargparse.ArgParser()
p.add('-e', '--execute', required=True, help='shell command to execute')
p.add('-v', help='verbose', action='store_true')
options = p.parse_args()

utils.init_logger(options.v)

if options.v is True:
    utils.debug_args(p)

utils.exec_shell(options.execute)
