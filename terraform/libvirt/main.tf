// Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = toset(var.hostnames)
  name = "${each.key}-commoninit.iso"
  pool = "default"
  user_data      = data.template_cloudinit_config.config[each.value].rendered
  network_config = data.template_file.network_config[each.value].rendered
}

// fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  for_each = toset(var.hostnames)
  name = "${each.value}-os_image"
  pool = "default"
  source = "jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}


// Create the machine node
resource "libvirt_domain" "host" {
  for_each = toset(var.hostnames)
  name = "${each.value}-vm"
  memory = var.memoryMB
  vcpu = var.cpu

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  disk {
    volume_id = libvirt_volume.os_image["${each.key}"].id
  }
  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}
