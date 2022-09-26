#!/bin/env python3
from etcdutils import MyEtcd
import sys,os

s=MyEtcd()
if sys.argv[1].endswith('*'):
	for k,v in s.get_prefix(sys.argv[1].split('*')[0]):
		print("%s\t%s" % (k, v))
else:
	res=s.get(sys.argv[1])
	if res != None:
		print("%s\t%s" % (sys.argv[1], res))
		sys.stdout.flush()
		os._exit(0)
os._exit(127)