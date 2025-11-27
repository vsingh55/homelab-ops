# Define variables 

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
  type    = string
}

variable "passwordGW" {
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