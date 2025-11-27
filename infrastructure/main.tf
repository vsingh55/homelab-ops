
# ==========================================
# ZONE A: PRODUCTION (LXC Containers)
# ==========================================

resource "proxmox_lxc" "gateway" {
  target_node  = "pve"
  hostname     = "gateway"
  vmid         = 100
  ostemplate = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" # Ensure you have this template or similar
  password     = "BasicLXC!23"
  unprivileged = true
  cores        = 1
  memory       = 512
  swap         = 512
  onboot       = true
  start        = true
  startup = "order=1,up=0,down=0"

  # Static IP: 192.168.0.10
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

# 1. Jumpbox (The Command Center)
resource "proxmox_vm_qemu" "jumpbox" {
  target_node = "pve"
  name        = "jumpbox"
  vmid        = 200
  clone       = "ubuntu-cloud-24.04"

  # ✅ CRITICAL FIX 1: Explicitly define the disks so Terraform keeps them attached
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

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  # ✅ CRITICAL FIX 2: Force boot from Hard Disk
  boot = "order=scsi0;net0"

  # Display Fix
  vga {
    type = "std" 
  }

  # CPU & Memory
  cpu {
    cores = 1
  }
  memory      = 1024
  scsihw      = "virtio-scsi-pci"
  
  # Startup & Boot Settings
  onboot      = true
  startup     = "order=4,up=40,down=40"

  # SSH Config Injection
  provisioner "local-exec" {
    command = <<EOT
      echo "Host jumpbox
        HostName 192.168.0.20
        User devops
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
  
  # Cloud-Init Settings
  ciuser      = var.ci_user
  sshkeys     = var.ssh_key
  ipconfig0   = "ip=192.168.0.20/24,gw=192.168.0.1"
}

# 2. Server (Control Plane)
resource "proxmox_vm_qemu" "server" {
  target_node = "pve"
  name        = "server"
  vmid        = 210
  clone       = "ubuntu-cloud-24.04"

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
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

  boot = "order=scsi0;net0"

  cpu {
    cores = 2
  }
  vga {
    type = "std" 
  }

  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  # Startup & Boot Settings
  onboot      = true
  startup = "order=3,up=40,down=40"
# SSH Config Injection
  provisioner "local-exec" {
    command = <<EOT
      echo "Host server
        HostName 192.168.0.21
        User devops
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }

  ciuser      = var.ci_user
  sshkeys     = var.ssh_key
  ipconfig0   = "ip=192.168.0.21/24,gw=192.168.0.1"
}

# 3. Node-0 (Worker)
resource "proxmox_vm_qemu" "node_0" {
  target_node = "pve"
  name        = "node-0"
  vmid        = 220
  clone       = "ubuntu-cloud-24.04"
  # ✅ CRITICAL FIX 1: Explicitly define the disks so Terraform keeps them attached
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
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  # ✅ CRITICAL FIX 2: Force boot from Hard Disk
  boot = "order=scsi0;net0"

  # Display Fix 
  vga {
    type = "std" 
  }
  cpu {
    cores = 2
  }
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  # Startup & Boot Settings
  onboot      = true
  startup = "order=3,up=40,down=40"
  
# SSH Config Injection
  provisioner "local-exec" {
    command = <<EOT
      echo "Host node-0
        HostName 192.168.0.22
        User devops
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
  ciuser      = var.ci_user
  sshkeys     = var.ssh_key
  ipconfig0   = "ip=192.168.0.22/24,gw=192.168.0.1"
}

# 4. Node-1 (Worker)
resource "proxmox_vm_qemu" "node_1" {
  target_node = "pve"
  name        = "node-1"
  vmid        = 221
  clone       = "ubuntu-cloud-24.04"

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
  cpu {
    cores = 2
  }
  vga {
    type = "std" 
  }
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
# SSH Config Injection
  provisioner "local-exec" {
    command = <<EOT
      echo "Host node-1
        HostName 192.168.0.23
        User devops
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
#   cloudinit_cdrom_storage = "local-lvm"
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  onboot      = true 
  startup = "order=3,up=20,down=20"
  
  ciuser      = var.ci_user
  sshkeys     = var.ssh_key
  ipconfig0   = "ip=192.168.0.23/24,gw=192.168.0.1"
}