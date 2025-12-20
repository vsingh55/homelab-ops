variable "gcp_project_id" {
  description = "The ID of the Google Cloud Project"
  type        = string
}

variable "gcp_region" {
  description = "Region for GCP resources"
  type        = string
  default     = "asia-south1" # Mumbai (Lowest Latency for you)
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
