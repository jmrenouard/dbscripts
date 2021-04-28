
import glob
import os
defaults = {
    # Ansible VM Parameter
    'ansible_base_box'      : 'jmrenouard/centos8',
    'ansible_vm_name'       : 'ansible',
    'ansible_vm_private_ip' : '192.168.33.170',
    'ansible_shared_source' : './data',
    'ansible_shared_target' : '/data',
    'ansible_ram'           : 1024,
    'ansible_vcpu'          : 2,

    'vm_number'             : 5,
    'vm_base_box'           : 'jmrenouard/centos8',
    'vm_name_prefix'        : 'vm',
    'vm_private_ip_prefix'  : '192.168.33.',
    'vm_private_ip_postfix' : 170,
    'vm_shared_source'      : './data',
    'vm_shared_target'      : '/data',
    'vm_ram'                : 1024,
    'vm_vcpu'               : 1,
}


def merge_params(conf, params):
    result = defaults
    for arg in params:
        kv = arg.split('=')
        if len(kv) == 2:
            result[kv[0]] = kv[1]
    return result


def rmWildCard(pattern):
    for filePath in glob.glob(pattern):
        try:
            os.remove(filePath)
        except:
            print("Error while deleting file : ", filePath)
