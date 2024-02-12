
output "hosts" {
  value = "${libvirt_domain.host.*}"
}