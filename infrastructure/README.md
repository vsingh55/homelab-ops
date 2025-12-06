# Infrastructure as Code (Terraform)

This directory contains the declarative infrastructure definitions for the Homelab. It uses **Proxmox** as the provider and **MinIO (S3)** as the remote backend.

## Structure
* **`main.tf`**: The core logic. Defines resources across 3 Zones:
    * **Zone M (Management):** `ops-center` (Critical Services).
    * **Zone P (Production):** `k3s-prod` (Persistent App Cluster).
    * **Zone A (Lab):** `gateway`, `server`, `nodes` (Ephemeral Learning Cluster).
* **`variables.tf`**: Type definitions for all inputs. **No values are set here.**
* **`provider.tf`**: Configures the Proxmox Telmate provider.
* **`backend.tf`**: Configures the Remote State (S3/MinIO). **Do not edit.**
* **`backend.conf`** (Ignored): Contains the Access/Secret keys for MinIO.
* **demo_files**: directory contains example files for setting your infra like; `backend.conf`, `terraform.tfvars` etc.  

## Workflows
**Provisioning:**
```bash
terraform init -backend-config=backend.conf
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

**State Management:** 
State is locked and versioned in the terraform-state bucket on ops-center. If the lock gets stuck (rare):
```bash
terraform force-unlock <LOCK_ID>
```