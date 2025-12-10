output "ops_center_ip" {
  description = "Management Node IP"
  value       = module.ops_center.ipv4_address
}

output "k3s_prod_ip" {
  description = "Production Cluster IP"
  value       = module.k3s_prod.ipv4_address
}

output "lab_cluster_nodes" {
  description = "Map of Lab Cluster Nodes and their IPs"
  value = {
    for k, v in module.k8s_cluster : k => v.ipv4_address
  }
}

output "next_steps" {
  value = "Infrastructure ready. # Start Lab Run: ansible-playbook playbooks/manage_lab.yml --tags start_lab"
}