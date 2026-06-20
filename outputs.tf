output "public_ip" {
  value = data.oci_core_vnic.server.public_ip_address
}

output "instance_id" {
  value = oci_core_instance.server.id
}
