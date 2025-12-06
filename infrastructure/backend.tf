terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "homelab/terraform.tfstate"
    
    # The bucket storage endpoint for MinIO Compatibility
    endpoints = {
      s3 = "http://100.87.130.97:9000"  # IMPORTANT: Use API Port 9000, NOT Console 9001
    }

    region                      = "ap-south-1" # MinIO requires a non-empty region
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true   # Required for MinIO
  }
}