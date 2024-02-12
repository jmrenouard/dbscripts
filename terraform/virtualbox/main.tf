terraform {
  required_providers {
    virtualbox = {
      source = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

resource "virtualbox_vm" "node" {
    count = 3
    name = "${format("mysql-%02d", count.index+1)}"
    image = "https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.2.12/providers/virtualbox.box"
    cpus = 2
    memory = "1024 mib"

    network_adapter {
      type = "bridged"
      host_interface="Surface Ethernet Adapter"
    }
}

output "IPAddr" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
}

output "IPAddr_2" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 2)
}
