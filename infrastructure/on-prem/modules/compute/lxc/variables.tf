variable "target_node" {}
variable "hostname" {}
variable "vmid" {}
variable "ostemplate" {}
variable "password" {}
variable "ssh_key" {}
variable "cores" {}
variable "memory" {}
variable "swap" { default = 512 }
variable "ip_address" {}
variable "gateway_ip" {}
variable "storage_pool" { default = "local-lvm" }
variable "disk_size" { default = "8G" }
variable "onboot" {}