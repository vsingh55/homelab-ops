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

variable "passwordGW" {
  type        = string
  sensitive   = true
  description = "Password for the Gateway LXC"
}

variable "vm_template" {
  type        = string
  default     = "ubuntu-cloud-24.04"
  description = "Name of the VM template to clone"
}

variable "lxc_template" {
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  description = "LXC Template path"
}

# ==============================================
# Resource Configurations
# ==============================================

variable "gateway_config" {
  description = "Configuration for the Gateway LXC"
  type = object({
    ip = string
    onboot = bool
  })
}

variable "vms" {
  description = "Map of VM configurations for the Kubernetes Lab cluster"
  type = map(object({
    vmid          = number
    ip            = string
    cores         = number
    memory        = number
    startup_param = string
    onboot        = bool
  }))
}

variable "ops_center_config" {
  description = "Configuration for the Management Node"
  type = object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = string
    onboot    = bool
  })
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