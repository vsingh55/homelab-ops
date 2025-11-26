# Define variables so we don't hardcode secrets
variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_api_url" {
  type = string
}

# Common variables for all VMs
variable "ci_user" {
  default = "devops"  # This will be your username inside the VMs
}
variable "ssh_key" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLBRLuIw6ZBC/6xYG/kH/Q90D4Js3DJ396gpIEg4GNX vsc@fedora" # ⚠️ REPLACE THIS WITH YOUR REAL PUBLIC KEY (cat ~/.ssh/id_rsa.pub)
}