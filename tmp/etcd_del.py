#!/bin/env python3
from etcdutils import MyEtcd
import sys,os 


if sys.argv[1].endswith('*'):
	MyEtcd().delete_prefix(sys.argv[1].split('*')[0])
else:
	MyEtcd().delete(sys.argv[1])

os._exit(0)