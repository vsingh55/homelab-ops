terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04" # Using a stable version for Proxmox 8/9
    }
  }
}

provider "proxmox" {
  # URL of your Proxmox API
  pm_api_url = var.proxmox_api_url

  # Authentication (Using the Token you just created)
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_minimum_permission_check = false

  # Security (Ignore self-signed certs)
  pm_tls_insecure = true
}
