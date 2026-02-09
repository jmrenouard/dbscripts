#!/usr/bin/env python3

import socket
import time
import sys

if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} <ip> <port>", file=sys.stderr)
    sys.exit(1)

ip = sys.argv[1]
try:
    port = int(sys.argv[2])
except ValueError:
    print(f"Error: Port must be an integer, got '{sys.argv[2]}'", file=sys.stderr)
    sys.exit(1)

retry = 3
delay = 1
timeout = 2

def isOpen(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((ip, int(port)))
        s.shutdown(socket.SHUT_RDWR)
        return True
    except Exception:
        return False
    finally:
        s.close()

def checkHost(ip, port):
    ipup = False
    for i in range(retry):
        sys.stdout.write('.')
        sys.stdout.flush()
        if isOpen(ip, port):
            ipup = True
            break
        else:
            time.sleep(delay)
    return ipup

if checkHost(ip, port):
    print(f"\n{ip} is UP")
else:
    print(f"\n{ip} is DOWN")
    sys.exit(1)
