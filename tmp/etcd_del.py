#!/bin/env python3
from etcdutils import MyEtcd
import sys

MyEtcd().delete(sys.argv[1])

os._exit(0)