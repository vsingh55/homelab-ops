output "k3s_prod_ip" {
  description = "Production Cluster IP"
  value       = module.k3s_prod.ipv4_address
}

output "next_steps" {
  value = "Infrastructure ready."
}