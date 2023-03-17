terraform {
  required_version = ">= 0.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

// instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}
