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
  pm_api_token_id             = var.proxmox_api_token_id
  pm_api_token_secret         = var.proxmox_api_token_secret

  # Standard Performance Options
  pm_minimum_permission_check = false
  pm_tls_insecure             = true
  pm_parallel                 = 1
  pm_timeout                  = 600 
}

