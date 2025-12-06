# ==========================================
# ZONE A: PRODUCTION (LXC Containers)
# ==========================================

resource "proxmox_lxc" "gateway" {
  target_node     = var.target_node
  hostname        = "gateway"
  vmid            = 100
  ostemplate      = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password        = var.passwordGW
  unprivileged    = true
  ssh_public_keys = var.ssh_key

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
  provisioner "local-exec" {
    command = <<EOT
      echo "Host gateway
        HostName 192.168.0.10
        User root
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
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

# ==========================================
# ZONE M: MANAGEMENT (The Ops-Center)
# ==========================================

resource "proxmox_vm_qemu" "ops_center" {
  target_node = var.target_node
  name        = "ops-center"
  vmid        = var.ops_center_config.vmid
  clone       = "ubuntu-cloud-24.04" # This could be a variable too, but standard template is fine for now.

 # Hardware Config
  cpu {
    cores = var.ops_center_config.cores
  }
  memory = var.ops_center_config.memory
  scsihw = "virtio-scsi-pci"

  # Display
  vga {
    type = "std"
  }

  # Network
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot & Disk
  boot = "order=scsi0;net0"
  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = var.ops_center_config.disk_size
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

  # Cloud-Init & Auth
  ciuser    = var.ci_user
  sshkeys   = var.ssh_key
  ipconfig0 = "ip=${var.ops_center_config.ip}/24,gw=192.168.0.1"

  # SSH Config Injection (Dynamic)
  provisioner "local-exec" {
    command = <<EOT
      echo "Host ops-center
        HostName ${var.ops_center_config.ip}
        User ${var.ci_user}
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
}