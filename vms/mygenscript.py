#!/usr/bin/env python3

import sys
import datetime
from config import defaults, merge_params, rmWildCard

def generate_bat_scripts(_metaconf):
    generate_bat_script(_metaconf['ansible_vm_name'], _metaconf['ansible_vm_private_ip'])
    for vmid in range(1, _metaconf['vm_number']+1):
        vmname=_metaconf['vm_name_prefix'] + str(vmid);
        vmpip=int(_metaconf['vm_private_ip_postfix'])+int(vmid);
        vmpip=_metaconf['vm_private_ip_prefix']+str(vmpip)
        generate_bat_script(vmname, vmpip)

def generate_bat_script(name, ip, user="vagrant", private_key="./private.ppk"):
    outputFile="putty_%s.bat" % name
    with open(outputFile, 'w') as script:
        print(f"""echo Starting {name} Putty connexion TO {name} Virtual VM
putty.exe -ssh -v -l {user} -i {private_key} {ip}""", file=script)

def main(argv):
    actual_conf = merge_params(defaults, argv)

    rmWildCard('putty_*.bat')

    generate_bat_scripts(actual_conf)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))