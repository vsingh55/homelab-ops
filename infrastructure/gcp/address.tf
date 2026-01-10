resource "google_compute_address" "vpn_gateway_ip" {
  name   = "vpn-gateway-static-ip"
  region = var.gcp_region
}
