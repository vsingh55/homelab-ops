variable "tenancy_ocid" {
  description = "The OCID of your OCI tenancy (optional if using ~/.oci/config profile)."
  type        = string
  default     = null
  sensitive   = true
}

variable "user_ocid" {
  description = "The OCID of the OCI user calling the API (optional if using ~/.oci/config profile)."
  type        = string
  default     = null
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint for the OCI API private key (optional if using ~/.oci/config profile)."
  type        = string
  default     = null
  sensitive   = true
}

variable "private_key_path" {
  description = "The local absolute or home-relative path to the OCI API signing private key."
  type        = string
  default     = null
}


variable "compartment_id" {
  description = "The OCID of the compartment to contain all resources (use tenancy_ocid for root compartment)."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The OCI region to provision resources in."
  type        = string
  default     = "ap-mumbai-1"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key injected into the VM for devops / ubuntu user access."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "instance_shape" {
  description = "Compute instance shape. Always Free eligible: VM.Standard.A1.Flex (Ampere) or VM.Standard.E2.1.Micro (AMD)."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs allocated to the instance (Flex shapes only)."
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  description = "Memory in GB allocated to the instance (Flex shapes only)."
  type        = number
  default     = 6
}

variable "boot_volume_size_in_gbs" {
  description = "Size of the boot volume in GB (OCI Always Free provides up to 200GB total across tenancy)."
  type        = number
  default     = 50
}

variable "environment" {
  description = "Environment tag for OCI resources."
  type        = string
  default     = "production"
}
