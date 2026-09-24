data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "ubuntu" {
  compartment_id   = var.compartment_id
  operating_system = "Canonical Ubuntu"
  shape            = var.instance_shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

resource "oci_core_instance" "uptime_kuma" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "oci-uptime-kuma"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = length(regexall(".*Flex.*", var.instance_shape)) > 0 ? [1] : []
    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_in_gbs
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.homelab_public_subnet.id
    display_name     = "uptime-kuma-vnic"
    assign_public_ip = true
    hostname_label   = "uptime-kuma"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
    user_data = base64encode(<<-EOF
      #!/usr/bin/env bash
      set -euo pipefail
      echo "Bootstrapping OCI Uptime Kuma instance..."
      apt-get update
      apt-get install -y ca-certificates curl gnupg ufw python3-apt
      ufw allow 22/tcp
      ufw allow 3001/tcp
      ufw --force enable
    EOF
    )
  }

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "Role"        = "monitoring"
    "ManagedBy"   = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
}
