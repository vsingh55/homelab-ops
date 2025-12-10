terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
    }
  }
}

resource "proxmox_lxc" "lxc" {
  target_node     = var.target_node
  hostname        = var.hostname
  vmid            = var.vmid
  ostemplate      = var.ostemplate
  password        = var.password
  unprivileged    = true
  ssh_public_keys = var.ssh_key

  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  onboot  = var.onboot
  start   = true
  startup = "order=1,up=0,down=0"

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.ip_address}/24"
    gw     = var.gateway_ip
  }

  rootfs {
    storage = var.storage_pool
    size    = var.disk_size
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Host ${var.hostname}
        HostName ${var.ip_address}
        User root
        IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    EOT
  }
}