resource "google_compute_instance" "vpn_gateway" {
  name         = "vm-${local.base_name}-gateway"
  machine_type = "e2-micro"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    
    access_config {
      nat_ip = google_compute_address.vpn_gateway_ip.address
    }
  }

  metadata = {
    enable-oslogin = "TRUE" 
  }

  
  scheduling {
    preemptible                 = false
    automatic_restart           = false
    provisioning_model          = "STANDARD"
  }
  
  tags = ["vpn-gateway", "http-server", "https-server"]
  
}