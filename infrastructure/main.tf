
# ==========================================
# 🏗️ ZONE A: PRODUCTION (LXC Containers)
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
# 🎓 ZONE B: ACADEMY (KTHW VMs)
# ==========================================

# 1. Jumpbox (The Command Center)
resource "proxmox_vm_qemu" "jumpbox" {
  target_node = "pve"
  name        = "jumpbox"
  vmid        = 200
  clone       = "ubuntu-cloud-24.04" # Must match your template name exactly
  cpu {
    cores = 1
  }
  memory      = 1024
  scsihw      = "virtio-scsi-pci"
  
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
  cpu {
    cores = 2
  }
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  
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
  cpu {
    cores = 2
  }
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  
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
  cpu {
    cores = 2
  }
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  
  ciuser      = var.ci_user
  sshkeys     = var.ssh_key
  ipconfig0   = "ip=192.168.0.23/24,gw=192.168.0.1"
}