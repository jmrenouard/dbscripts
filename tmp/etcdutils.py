#!/bin/env python3
import etcd3, sys, os
import configparser
from pprint import pprint

class MyEtcd():
	def __init__(self, confFile="%s/.etcd3.conf" % os.environ['HOME']):
		if oct(os.stat(confFile).st_mode)[-3:] != "600":
			print( "Config file: %s Must be 600 UNIX rights in order to be used." % confFile, file=sys.stderr)
			os._exit(1)
		self.configfile=confFile
		self.config = configparser.ConfigParser()
		self.config.read(confFile)
		if 'user' in self.config['server'].keys():
			self.etcd = etcd3.client(host=self.config['server']['host'], port=int(self.config['server']['port']), user=self.config['server']['user'], password=self.config['server']['password'])
		else:
			self.etcd = etcd3.client(host=self.config['server']['host'], port=int(self.config['server']['port']))
	
	def get(self, key='/toto'):
		try:
			result=self.etcd.get(key)[0].decode()
		except:
			result=None
		return result

	def put(self, key, value):
		self.etcd.put(key, value)
		return self.get(key)

	def delete(self, key):
		self.etcd.delete(key)

	def get_all(self):
		res=[]
		for elt in self.etcd.get_all():
			res.append( (elt[1].key.decode(), elt[0].decode() ) )
		return res

	def get_all_keys(self):
		res=[]
		for elt in self.etcd.get_all():
			res.append( elt[1].key.decode() )
		return res

	def load_tests(self):
		for i in range(1, 100):
			self.put("/testb/%d" % i, "ValueOf_%d" % i)