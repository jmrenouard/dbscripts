#!/bin/env python3
import socket, sys, os
from pprint import pprint
from pathlib import Path

# Function to display hostname and ip
def get_ip_from_hostname(hostname): 
	host_ip="N/A"
	try: 
		host_ip = socket.gethostbyname(hostname) 
	except: 
		print(f"Unable to get Hostname and IP {hostname}", file=sys.stderr)
	return host_ip

for input_file in sys.argv[1:]:
	output_file= "%s_result.csv" % Path(input_file).with_suffix('')
	if os.path.exists(output_file):
		os.remove(output_file)
	with open(output_file, 'w') as fout:
		with open(input_file) as fp:
			line = fp.readline().strip()
			while line:
				print( f"{line}\t{get_ip_from_hostname(line)}", file=fout )
				line = fp.readline().strip()
