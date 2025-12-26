terraform {
  backend "gcs" {
    bucket  = "homelab-gcp-tfstate" # Replace with your ACTUAL bucket name
    prefix  = "gcp/terraform.tfstate"
  }
}