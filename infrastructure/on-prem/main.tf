# ==========================================================
# HOMELAB-OPS: ON-PREMISES PRODUCTION INFRASTRUCTURE
# ==========================================================

# Zone P: PROD (Application Plane - K3s)
module "k3s_prod" {
  source = "./modules/compute/vm"

  target_node   = var.target_node
  vm_name       = "k3s-prod"
  vmid          = var.k3s_prod_config.vmid
  template_name = var.vm_template

  cores         = var.k3s_prod_config.cores
  memory        = var.k3s_prod_config.memory
  disk_size     = var.k3s_prod_config.disk_size
  
  # 1TB SATA HDD Data Disk Attachment (Cold Tier for Media, Books, Backups)
  data_disk_size    = "500G"
  data_disk_storage = "backup-hdd"
  
  agent_enabled = 1
  onboot        = var.k3s_prod_config.onboot

  ci_user    = var.ci_user
  ssh_key    = var.ssh_key
  ip_address = var.k3s_prod_config.ip
  gateway_ip = "192.168.1.1" # Physical Router IP
}
