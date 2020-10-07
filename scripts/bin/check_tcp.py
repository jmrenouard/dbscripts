
#!/usr/bin/python

import socket
import time
import sys

ip = sys.argv[1]
port = int(sys.argv[2])
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
        except:
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
        print ip + " is UP"
else:
        print ip + " is DOWN"
