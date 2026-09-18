output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway"
  value       = google_compute_instance.vpn_gateway.network_interface.0.access_config.0.nat_ip
}

output "vpn_gateway_internal_ip" {
  description = "Internal IP of the VPN Gateway (for routing)"
  value       = google_compute_instance.vpn_gateway.network_interface.0.network_ip
}

# Outputs needed for your GitHub Actions YAML
output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Add this to GitHub Secrets as WIF_PROVIDER"
}

output "service_account_email" {
  value       = google_service_account.github_actions_sa.email
  description = "Add this to GitHub Secrets as GCP_SA_EMAIL"
}