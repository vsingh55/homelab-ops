resource "google_compute_instance" "vpn_gateway" {
  name         = "vm-${local.base_name}-gateway"
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
      # Ephemeral Public IP
    }
  }

  metadata = {
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