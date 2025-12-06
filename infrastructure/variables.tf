# Define variables for common Proxmox and VM configurations

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "target_node" {
  type    = string
  default = "pve"
}

variable "ci_user" {
  type    = string
  default = "devops"
}

variable "ssh_key" {
  type = string
}

variable "passwordGW" {
  type = string
}

# The Variables for Gateway VM
variable "gateway_ip" {
  type = string
}

# The Map Variable for all K8s VMs
variable "vms" {
  description = "Map of VM configurations for the Kubernetes cluster"
  type = map(object({
    vmid          = number
    ip            = string
    cores         = number
    memory        = number
    startup_param = string
  }))
}

# The Variables for ops-center VM
variable "ops_center_config" {
  description = "Configuration for the Management Node"
  type = object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = string # Ops-Center is bigger (20G) than the others
  })
}

# The Variables for k3s-prod 
variable "k3s_prod_config" {
  description = "Configuration for the Production K3s Node"
  type = object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = string
  })
}