# ==========================================
# ZONE A: PRODUCTION (LXC Containers)
# ==========================================

resource "proxmox_lxc" "gateway" {
  target_node  = var.target_node
  hostname     = "gateway"
  vmid         = 100
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "BasicLXC!23"
  unprivileged = true
  
  cores  = 1
  memory = 512
  swap   = 512
  
  onboot  = true
  start   = true
  startup = "order=1,up=0,down=0"

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.0.10/24"
    gw     = "192.168.0.1"
  }
  
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }
}

# ==========================================
# ZONE B: ACADEMY (KTHW VMs)
# ==========================================

resource "proxmox_vm_qemu" "k8s_cluster" {
  # The Magic Loop: Creates a VM for every entry in the 'vms' variable
  for_each = var.vms

  target_node = var.target_node
  name        = each.key
  vmid        = each.value.vmid
  clone       = "ubuntu-cloud-24.04"

  # Hardware Config
  cpu {
    cores = each.value.cores
  }
  memory = each.value.memory
  scsihw = "virtio-scsi-pci"
  
  # Display
  vga {
    type = "std" 
  }

  # Storage Configuration
  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "8G"
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  # Network Configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Boot Order
  boot    = "order=scsi0;net0"
  onboot  = true
  startup = each.value.startup_param

  # Cloud-Init & Auth
  ciuser    = var.ci_user
  sshkeys   = var.ssh_key
  ipconfig0 = "ip=${each.value.ip}/24,gw=192.168.0.1"

  # SSH Config Injection (Dynamic)
  provisioner "local-exec" {
    command = <<EOT
      echo "Host ${each.key}
        HostName ${each.value.ip}
        User ${var.ci_user}
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
}