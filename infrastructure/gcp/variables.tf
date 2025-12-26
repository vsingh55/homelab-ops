variable "gcp_project_id" {
  description = "The ID of the Google Cloud Project"
  type        = string
}

variable "project_name" {
  description = "Base name for the project (e.g., homelab)"
  type        = string
  default     = "homelab"
}

variable "environment" {
  description = "Environment (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "gcp_region" {
  description = "Region for GCP resources"
  type        = string
  default     = "asia-south1" # Mumbai
}

variable "gcp_zone" {
  description = "Zone for GCP resources"
  type        = string
  default     = "asia-south1-a"
}

variable "subnet_cidr" {
  description = "CIDR block for the Mumbai subnet"
  type        = string
  default     = "10.0.1.0/24"
}