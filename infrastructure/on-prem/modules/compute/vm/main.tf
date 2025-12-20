terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  target_node = var.target_node
  name        = var.vm_name
  vmid        = var.vmid
  clone       = var.template_name

  # Hardware & Display Configuration
  cpu {
    cores = var.cores
  }
  memory  = var.memory
  scsihw  = "virtio-scsi-pci"
  agent   = var.agent_enabled # Exposed for K3s/Ops Center

  vga {
    type = "std"
  }

  # Network Configuration
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot & Disk Configuration
  boot    = "order=scsi0;net0"
  onboot  = var.onboot
  vm_state = var.onboot ? "running" : "stopped"
  startup = var.startup_param

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage_pool
          size    = var.disk_size
        }
      }
      
      # block to only create scsi1 if size is not "0G"
      dynamic "scsi1" {
        for_each = var.data_disk_size != "0G" ? [1] : []
        content {
          disk {
            storage = var.data_disk_storage
            size    = var.data_disk_size
          }
        }
      }
    }

    ide {
      ide2 {
        cloudinit {
          storage = var.storage_pool
        }
      }
    }
  }


  # Cloud-Init & Auth

  ciuser    = var.ci_user
  sshkeys   = var.ssh_key
  ipconfig0 = "ip=${var.ip_address}/24,gw=${var.gateway_ip}"

  # This allows Proxmox to reclaim "Cache" memory from the VM
  balloon = 1
  
  # To fix tag drift issues with Proxmox UI and API 
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
  
  # SSH Config Injection (Local Convenience)

  provisioner "local-exec" {
    command = <<EOT
      echo "Host ${var.vm_name}
        HostName ${var.ip_address}
        User ${var.ci_user}
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
}