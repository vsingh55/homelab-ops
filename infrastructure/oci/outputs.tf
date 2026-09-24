output "instance_id" {
  description = "The OCID of the provisioned Uptime Kuma instance."
  value       = oci_core_instance.uptime_kuma.id
}

output "instance_public_ip" {
  description = "The public IPv4 address of the Uptime Kuma instance."
  value       = oci_core_instance.uptime_kuma.public_ip
}

output "instance_private_ip" {
  description = "The private IPv4 address within the VCN."
  value       = oci_core_instance.uptime_kuma.private_ip
}

output "uptime_kuma_dashboard_url" {
  description = "Direct web URL to access the Uptime Kuma monitoring portal."
  value       = "http://${oci_core_instance.uptime_kuma.public_ip}:3001"
}

output "ssh_command" {
  description = "Convenience SSH command to connect to the OCI instance."
  value       = "ssh ubuntu@${oci_core_instance.uptime_kuma.public_ip}"
}
