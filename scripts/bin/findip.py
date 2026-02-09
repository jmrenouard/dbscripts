#!/usr/bin/env python3
import socket
import sys
import os
from pathlib import Path

# Function to display hostname and ip
def get_ip_from_hostname(hostname): 
    host_ip = "N/A"
    try: 
        host_ip = socket.gethostbyname(hostname) 
    except socket.gaierror: 
        print(f"Unable to get Hostname and IP for {hostname}", file=sys.stderr)
    except Exception as e:
        print(f"Unexpected error resolving {hostname}: {e}", file=sys.stderr)
    return host_ip

if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} <input_file1> [input_file2 ...]", file=sys.stderr)
    sys.exit(1)

for input_file in sys.argv[1:]:
    if not os.path.exists(input_file):
        print(f"File not found: {input_file}", file=sys.stderr)
        continue

    output_file = f"{Path(input_file).stem}_result.csv"
    if os.path.exists(output_file):
        os.remove(output_file)
        
    try:
        with open(output_file, 'w') as fout:
            with open(input_file) as fp:
                for line in fp:
                    hostname = line.strip()
                    if not hostname:
                        continue
                    ip = get_ip_from_hostname(hostname)
                    fout.write(f"{hostname}\t{ip}\n")
        print(f"Results written to {output_file}")
    except Exception as e:
        print(f"Error processing {input_file}: {e}", file=sys.stderr)
