output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway"
  value       = google_compute_instance.vpn_gateway.network_interface.0.access_config.0.nat_ip
}

output "vpn_gateway_internal_ip" {
  description = "Internal IP of the VPN Gateway (for routing)"
  value       = google_compute_instance.vpn_gateway.network_interface.0.network_ip
}