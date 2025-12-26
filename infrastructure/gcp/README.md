# Sovereign Cloud - GCP Infrastructure

This directory contains the Terraform configuration for the **Public Cloud Extension** of the Homelab. It provisions a cost-optimized, secure network in Mumbai (`asia-south1`) to act as the gateway for the Hybrid Cloud.

## Architecture

* **VPC:** Custom VPC (`vpc-homelab-prod`) with a single subnet.
* **Connectivity:** WireGuard VPN Gateway acting as a "Site-to-Site" bridge.
* **Compute:** `e2-micro` Spot Instance (Preemptible) to minimize costs (~$3/mo).
* **Security:**
    * Cloud NAT (Private Egress)
    * Firewall Rules (Allow UDP/51820 only)
    * OS Login (Keyless SSH)

## File Structure

| File | Purpose |
| :--- | :--- |
| `network.tf` | VPC, Subnet, NAT, Router, and Firewall definitions. |
| `compute.tf` | The VPN Gateway VM (Spot Instance). |
| `locals.tf` | Naming convention logic (`[resource]-[env]-[region]`). |
| `variables.tf` | Input variable definitions. |
| `backend.tf` | GCS Bucket configuration for remote state. |

## Usage

**1. Authenticate with GCP:**
```bash
# 1. Login to Google Cloud
gcloud auth login

# 2. Set your project ID (Replace 'YOUR_PROJECT_ID' with the actual ID from GCP Console)
gcloud config set project YOUR_PROJECT_ID

# 3. Create Application Default Credentials (ADC) for Terraform
gcloud auth application-default login
```
**2. Create the Bucket (Manually):**
```bash
# Create a unique bucket name (e.g., vsingh-tfstate)
gsutil mb -p YOUR_PROJECT_ID -l asia-south1 -b on gs://vsingh-tfstate

# Enable versioning (Restores state if you accidentally delete it)
gsutil versioning set on gs://vsingh-tfstate
```

**3. Update variables:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project-specific values
```

**4. Provision the Cloud resources:**
```bash
cd infrastructure/gcp

# Initialize (if not done recently)
terraform init

# Plan (Verify what will be built)
terraform plan

# Apply (Build it!)
terraform apply
```