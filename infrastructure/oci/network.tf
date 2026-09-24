resource "oci_core_vcn" "homelab_vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.10.0.0/16"]
  display_name   = "homelab-mumbai-vcn"
  dns_label      = "homelaboci"

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "ManagedBy"   = "Terraform"
  }
}

resource "oci_core_internet_gateway" "homelab_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homelab_vcn.id
  display_name   = "homelab-internet-gateway"
  enabled        = true

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "ManagedBy"   = "Terraform"
  }
}

resource "oci_core_default_route_table" "homelab_default_route" {
  manage_default_resource_id = oci_core_vcn.homelab_vcn.default_route_table_id
  display_name               = "homelab-default-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.homelab_igw.id
  }

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "ManagedBy"   = "Terraform"
  }
}

resource "oci_core_security_list" "homelab_public_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.homelab_vcn.id
  display_name   = "homelab-public-security-list"

  # Outbound: Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Inbound: SSH (Port 22)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
    description = "SSH administrative access"
  }

  # Inbound: Uptime Kuma Web UI (Port 3001)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 3001
      max = 3001
    }
    description = "Uptime Kuma status portal and dashboard"
  }

  # Inbound: HTTP (Port 80)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
    description = "HTTP standard web access (for reverse proxy)"
  }

  # Inbound: HTTPS (Port 443)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
    description = "HTTPS secure web access for status page"
  }

  # Inbound: ICMP Ping
  ingress_security_rules {
    protocol  = "1" # ICMP
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = 8 # Echo request
      code = 0
    }
    description = "ICMP Ping"
  }

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "ManagedBy"   = "Terraform"
  }
}

resource "oci_core_subnet" "homelab_public_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.homelab_vcn.id
  cidr_block                 = "10.10.1.0/24"
  display_name               = "homelab-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_default_route_table.homelab_default_route.id
  security_list_ids          = [oci_core_security_list.homelab_public_security_list.id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    "Environment" = var.environment
    "Project"     = "homelab-ops"
    "ManagedBy"   = "Terraform"
  }
}
