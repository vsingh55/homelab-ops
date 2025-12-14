variable "target_node" {}
variable "vm_name" {}
variable "vmid" {}
variable "template_name" {}
variable "cores" {}
variable "memory" {}
variable "disk_size" {}
variable "storage_pool" { default = "local-lvm" }
variable "agent_enabled" { default = 0 }
variable "startup_param" { default = "" }
variable "ci_user" {}
variable "ssh_key" {}
variable "ip_address" {}
variable "gateway_ip" {}
variable "onboot" {}
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