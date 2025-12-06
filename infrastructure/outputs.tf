output "ops_center_ip" {
  value = proxmox_vm_qemu.ops_center.default_ipv4_address
}

output "k8s_nodes" {
  value = {
    for k, v in proxmox_vm_qemu.k8s_cluster : k => v.default_ipv4_address
  }
}

output "next_steps" {
  value = "Infrastructure ready. Run: ansible-inventory -i inventory/hosts.yml --graph"
}