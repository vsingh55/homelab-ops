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