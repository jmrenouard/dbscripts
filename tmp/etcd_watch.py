#!/bin/env python3
from etcdutils import MyEtcd
import sys,os

s=MyEtcd()
if sys.argv[1].endswith('*'):
	events_iterator, cancel = s.watch_prefix(sys.argv[1].split('*')[0])
else:
	events_iterator, cancel = s.watch(sys.argv[1])

# watch key
watch_count = 0
max_watch_count=10
if len(sys.argv)>2:
	max_watch_count=int(sys.argv[2])

for event in events_iterator:
	print("WATCHER: %s\t%s" % (event.key.decode(), s.get(event.key)))
	watch_count += 1
	if watch_count > max_watch_count:
		cancel()