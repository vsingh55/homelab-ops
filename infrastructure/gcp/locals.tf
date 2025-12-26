locals {
  # Naming Convention: [resource]-[project]-[env]-[region]
  # Example: vpc-homelab-prod-mum
  base_name    = "${var.project_name}-${var.environment}"
  region_short = "mum"
}