#!/bin/env python3
from etcdutils import MyEtcd
import sys,os

res=MyEtcd().get(sys.argv[1])
if res != None:
	print("%s\t%s" % (sys.argv[1], res))
	sys.stdout.flush()
	os._exit(0)
os._exit(127)