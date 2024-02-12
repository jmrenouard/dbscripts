#!/bin/env python3
from etcdutils import MyEtcd
import sys,os

print("%s\t%s" % (sys.argv[1], MyEtcd().put(sys.argv[1], sys.argv[2])))

sys.stdout.flush()
os._exit(0)