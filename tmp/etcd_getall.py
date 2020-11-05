#!/bin/env python3
from etcdutils import MyEtcd
import sys,os

s=MyEtcd()

for k in s.get_all_keys():
	print("%s\t%s" % (k, s.get(k)))

sys.stdout.flush()
os._exit(0)