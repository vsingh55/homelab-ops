# 1. The VPC (Virtual Private Cloud)
resource "google_compute_network" "vpc" {
  name                    = "homelab-vpc"
  auto_create_subnetworks = false
}

# 2. The Subnet (Mumbai)
resource "google_compute_subnetwork" "subnet" {
  name          = "homelab-subnet-mumbai"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
}

# 3. Cloud NAT (Required for the VM to install updates without a public IP on every VM)
resource "google_compute_router" "router" {
  name    = "homelab-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "homelab-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 4. Firewall - Allow WireGuard Traffic
resource "google_compute_firewall" "allow_wireguard" {
  name    = "allow-wireguard-ingress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }
  
  # Allow SSH so Ansible can configure it
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Security Best Practice: restrict this Home Public IP later.
  source_ranges = ["0.0.0.0/0"] 
}

# 5. The VPN Gateway VM (Spot Instance for Cost Savings)
resource "google_compute_instance" "vpn_gateway" {
  name         = "vpn-gateway-mumbai"
  machine_type = "e2-micro" 
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      # This block assigns a Public IP (Ephemeral)
      # We need this for WireGuard to be reachable from home
    }
  }

  # metadata_startup_script = "apt-get update && apt-get install -y wireguard" 
  # (We will use Ansible instead of startup scripts for better control)

  metadata = {
    # This allows to SSH using OS Login if needed, 
    # but we'll stick to SSH keys for Ansible.
    enable-oslogin = "TRUE" 
  }

  # FinOps Strategy: Spot Provisioning
  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }
  
  tags = ["vpn-gateway"]
}