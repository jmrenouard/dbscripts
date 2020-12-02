#!/usr/bin/env python3

import sys
import datetime
from config import defaults, merge_params
from shell import Shell

def generate_bat_script(name, ip, user="root", private_key="./id_rsa.ppk"):
    outputFile="putty_%s.bat" % name
    with open(outputFile, 'w') as script:
        print(f"""echo Starting {name} Putty connexion TO {name} Virtual VM
putty.exe -ssh -v -l {user} -i {private_key} {ip}""", file=script)


def generate_bat_scripts(_metaconf):
    for i in range(1, _metaconf['nb_linode_vms']+1):
        lname=_metaconf['generic_prefix'] +'_' + _metaconf['vm_name_'+str(i)];
        lpip=get_public_ip(lname)
        print(lname + ' => ' + lpip)
        generate_bat_script(lname, lpip)


def main(argv):
    params=merge_params(defaults, argv)

    generate_bat_scripts(params)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))