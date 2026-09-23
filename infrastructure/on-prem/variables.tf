# ==============================================
# Global Proxmox Settings
# ==============================================
variable "proxmox_api_url" {
  type        = string
  description = "The endpoint for the Proxmox API"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "API Token ID"
}

variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "API Token Secret"
}

variable "target_node" {
  type        = string
  default     = "pve"
  description = "Target Proxmox Node Name"
}

# ==============================================
# Common Images & Auth
# ==============================================
variable "ci_user" {
  type    = string
  default = "devops"
}

variable "ssh_key" {
  type        = string
  description = "Public SSH Key for VM access"
}


variable "vm_template" {
  type        = string
  default     = "ubuntu-cloud-24.04"
  description = "Name of the VM template to clone"
}

# ==============================================
# Resource Configurations
# ==============================================

variable "data_disk_size" {
  description = "Size of the secondary data disk (e.g., 500G). Set to 0G to disable."
  type        = string
  default     = "0G"
}

variable "data_disk_storage" {
  description = "Proxmox Storage ID for the secondary disk"
  type        = string
  default     = "local-lvm"
}

variable "k3s_prod_config" {
  description = "Configuration for the Production K3s Node"
  type = object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = string
    onboot    = bool
  })
}