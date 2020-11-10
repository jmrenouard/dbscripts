#!/usr/bin/env python3

import sys
import datetime
from config import defaults, merge_params

def output_config(_metaconf):
    if 'output' in _metaconf.keys():
        _metaconf['out']=open(_metaconf['output'], "w")
    else:
        _metaconf['out']=sys.stdout
    _metaconf['datetime'] = '%s' % datetime.datetime.now()
    print("""### CONFIGURATED BY mygenconf.py at {datetime}
Vagrant.configure("2") do |config|
    ### CONFIG ansible vm GENERATED BY mygenconf
    config.vm.define "{ansible_vm_name}" do |{ansible_vm_name}|
      {ansible_vm_name}.vm.box = "{ansible_base_box}"
      {ansible_vm_name}.vm.hostname = '{ansible_vm_name}'
      {ansible_vm_name}.vm.network "private_network", ip: "{ansible_vm_private_ip}"
      {ansible_vm_name}.vm.network "public_network", type: "dhcp"

      {ansible_vm_name}.hostmanager.enabled = true
      {ansible_vm_name}.hostmanager.manage_host = false
      {ansible_vm_name}.hostmanager.manage_guest = true
      {ansible_vm_name}.hostmanager.ignore_private_ip = false
      {ansible_vm_name}.hostmanager.include_offline = true
      {ansible_vm_name}.hostmanager.aliases = %w({ansible_vm_name}.localdomain {ansible_vm_name}.local)

      {ansible_vm_name}.vm.synced_folder "{ansible_shared_source}", "{ansible_shared_target}", create: true

      {ansible_vm_name}.vm.provider "virtualbox" do |vb|
         vb.name="{ansible_vm_name}"
         vb.gui = false
         vb.memory = "{ansible_ram}"
         vb.cpus = {ansible_vcpu}
      end
      {ansible_vm_name}.vm.provision "shell", path: "provision_generic.sh"
      {ansible_vm_name}.vm.provision "shell", path: "provision_ansible.sh"
      {ansible_vm_name}.vm.provision :hostmanager
    end""".format(**_metaconf), file=_metaconf['out'])

    for vmid in range(1, _metaconf['vm_number']+1):
        _metaconf['vmid']=vmid;
        _metaconf['vmpip']=_metaconf['vm_private_ip_postfix']+vmid;

        print("""    ### CONFIG {vm_name_prefix}{vmid} vm GENERATED BY mygenconf
    config.vm.define "{vm_name_prefix}{vmid}" do |{vm_name_prefix}{vmid}|
      {vm_name_prefix}{vmid}.vm.box = "{vm_base_box}"
      {vm_name_prefix}{vmid}.vm.hostname = '{vm_name_prefix}{vmid}'
      {vm_name_prefix}{vmid}.vm.network "private_network", ip: "{vm_private_ip_prefix}{vmpip}"
      {vm_name_prefix}{vmid}.vm.network "public_network", type: "dhcp"
      {vm_name_prefix}{vmid}.hostmanager.enabled = true
      {vm_name_prefix}{vmid}.hostmanager.manage_host = false
      {vm_name_prefix}{vmid}.hostmanager.manage_guest = true
      {vm_name_prefix}{vmid}.hostmanager.ignore_private_ip = false
      {vm_name_prefix}{vmid}.hostmanager.include_offline = true
      {vm_name_prefix}{vmid}.hostmanager.aliases = %w({vm_name_prefix}{vmid}.localdomain {vm_name_prefix}{vmid}.local)

      {vm_name_prefix}{vmid}.vm.synced_folder "{vm_shared_source}", "{vm_shared_target}", create: true

      {vm_name_prefix}{vmid}.vm.provider "virtualbox" do |vb|
         vb.name="{vm_name_prefix}{vmid}"
         vb.gui = false
         vb.memory = "{vm_ram}"
         vb.cpus = {vm_vcpu}
      end
      {vm_name_prefix}{vmid}.vm.provision "shell", path: "provision_generic.sh"
      {vm_name_prefix}{vmid}.vm.provision :hostmanager
    end""".format(**_metaconf), file=_metaconf['out'])

    print("end", file=_metaconf['out'])
    if _metaconf['out']!=sys.stdout:
        _metaconf['out'].close()

def main(argv):
    output_config(merge_params(defaults, argv))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))