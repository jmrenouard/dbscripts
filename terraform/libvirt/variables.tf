// variables that can be overriden
variable "hostnames" {
  type=list(string)
  default = ["node1", "node2", "node3"]
}
variable "domain" { default = "local.domain" }
variable "ip_type" { default = "dhcp" } # dhcp is other valid type
variable "memoryMB" { default = 1024*2 }
variable "cpu" { default = 2 }

data "template_file" "user_data" {
  for_each = toset(var.hostnames)

  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = "${each.value}"
    fqdn = "${each.value}.${var.domain}"
    public_key = file("/home/jrenouard/.ssh/id_rsa_z51.pub")
  }
}

data "template_cloudinit_config" "config" {
  for_each = toset(var.hostnames)
  gzip = false
  base64_encode = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${data.template_file.user_data[each.key].rendered}"
  }
}

data "template_file" "network_config" {
  for_each = toset(var.hostnames)
  template = file("${path.module}/network_config_${var.ip_type}.cfg")
}
