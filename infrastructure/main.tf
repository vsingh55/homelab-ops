# ==============================================
# Zone A: Lab (Academy Plane) - Gateway
# ==============================================
module "gateway" {
  source = "./modules/compute/lxc"

  target_node  = var.target_node
  hostname     = "gateway"
  vmid         = 100
  ostemplate   = var.lxc_template
  password     = var.passwordGW
  ssh_key      = var.ssh_key
  cores        = 1
  memory       = 512
  ip_address   = var.gateway_config.ip
  gateway_ip   = "192.168.0.1" # Physical Router IP
  onboot       = var.gateway_config.onboot
}

# K8s Cluster

module "k8s_cluster" {
  source   = "./modules/compute/vm"
  for_each = var.vms

  target_node   = var.target_node
  vm_name       = each.key
  vmid          = each.value.vmid
  template_name = var.vm_template
  
  cores         = each.value.cores
  memory        = each.value.memory
  disk_size     = "8G" # Standard for lab nodes
  startup_param = each.value.startup_param
  onboot        = each.value.onboot
  ci_user       = var.ci_user
  ssh_key       = var.ssh_key
  ip_address    = each.value.ip
  gateway_ip    = var.gateway_config.ip # Gateway VM is the GW for Lab
}

# ==============================================
# Zone M: Management (The Ops-Center)
# ==============================================
module "ops_center" {
  source = "./modules/compute/vm"

  target_node   = var.target_node
  vm_name       = "ops-center"
  vmid          = var.ops_center_config.vmid
  template_name = var.vm_template

  cores         = var.ops_center_config.cores
  memory        = var.ops_center_config.memory
  disk_size     = var.ops_center_config.disk_size
  onboot        = var.ops_center_config.onboot
  
  ci_user       = var.ci_user
  ssh_key       = var.ssh_key
  ip_address    = var.ops_center_config.ip
  gateway_ip    = "192.168.0.1" # Direct access to physical router
}

# ==============================================
# Zone P: PROD (Application Plane - K3s)
# ==============================================
module "k3s_prod" {
  source = "./modules/compute/vm"

  target_node   = var.target_node
  vm_name       = "k3s-prod"
  vmid          = var.k3s_prod_config.vmid
  template_name = var.vm_template

  cores         = var.k3s_prod_config.cores
  memory        = var.k3s_prod_config.memory
  disk_size     = var.k3s_prod_config.disk_size
  agent_enabled = 1
  onboot        = var.k3s_prod_config.onboot

  ci_user       = var.ci_user
  ssh_key       = var.ssh_key
  ip_address    = var.k3s_prod_config.ip
  gateway_ip    = "192.168.0.1" 
}