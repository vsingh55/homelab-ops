# Terraform Refactoring: Modular Architecture

## Overview
As of December 2025, the infrastructure code has been refactored from a monolithic `main.tf` into reusable **Modules**. This change allows us to scale the homelab (adding nodes, swapping storage) without rewriting code, adhering to the "Don't Repeat Yourself" (DRY) principle.

## 1. The "Why" (The Challenge)
Initially, all VM definitions were hardcoded in a single `main.tf`. This created:
* **Code Duplication:** Defining `node-0`, `node-1`, and `server` required copying the same `proxmox_vm_qemu` block 3 times.
* **Rigidity:** Adding a secondary disk to just *one* VM (like `ops-center`) required hacking the main resource block or creating a separate one.

## 2. The Solution: Modules
I refactored the codebase into a `modules/` directory structure:

* **`modules/compute/vm`**: A generic blueprint for any Ubuntu VM.
* **`modules/compute/lxc`**: A generic blueprint for containers.

**Key Technical Feature: Dynamic Blocks**
To support the `ops-center` needing a 250GB Backup HDD while other nodes did not, I implemented a `dynamic` block in the module:

```hcl
# modules/compute/vm/main.tf
dynamic "scsi1" {
  for_each = var.data_disk_size != "0G" ? [1] : []
  content {
    disk {
      storage = var.data_disk_storage
      size    = var.data_disk_size
    }
  }
}
```
## 3. Engineering Challenges & Solutions
### Challenge A: The "Ghost Drift" (Tags)

**Symptom:** `terraform plan` persistently showed a change for tags, trying to change " " (space) to null. 

**Root Cause:** Proxmox's API defaulted empty tags to a space string, while Terraform's null value was strict. 

**Solution:** I accepted the drift once via terraform apply. Terraform corrected the Proxmox state to align with the code.

### Challenge B: State Loss During Storage Migration
**Symptom:** After mounting the HDD to ops-center and repointing MinIO to use it, `terraform plan` showed that it wanted to create all resources from scratch (6 to add). 

**Root Cause:** The MinIO container was now looking at the empty HDD (/mnt/storage/minio-data), while the terraform.tfstate file was still sitting on the old VM root disk. 

**Solution:**
*Restoration:* I located the backup terraform.tfstate file and restored it into the new MinIO bucket.

### Challenge C: The "Stop/Start" War
**Symptom:** Terraform tried to force stopped VMs (Lab Zone) to start, even though onboot = false was set.

**Root Cause:** The proxmox_vm_qemu resource defaults to ensuring VMs are running. 

**Solution:** I linked the state directly to the boot variable in the module:

```hcl
vm_state = var.onboot ? "running" : "stopped"
```

## Directory Structure
The new structure isolates logic (how a VM is created) from configuration (what VMs we want).

```bash
infrastructure/
├── demo_files/             # Files that are ignored, bring your own credentials and reemove .example extention
│   ├── backend.conf.example 
│   └── terraform.tfvars.example
├── modules/
│   └── compute/
│       ├── vm/             # Generic QEMU VM Logic
│       │   ├── main.tf     # Resource definition (proxmox_vm_qemu)
│       │   ├── variables.tf# Input interfaces
│       │   └── outputs.tf  # IPs, IDs
│       └── lxc/            # Generic LXC Container Logic
├── main.tf                 # Calls the modules
├── backend.conf            # ignored file
├── backend.tf              # S3 State configuration
├── variables.tf            # Global variables
└── terraform.tfvars        # The "Inventory" of our infrastructure (ignored file)
```
## Module Details
**1. Compute VM Module (modules/compute/vm)** 

This module handles the complexity of Proxmox VM creation, including:

**State Management:** Automatically handles stopped vs running state based on onboot variables.

**Dynamic Disk Allocation:** Conditionally provisions secondary storage (e.g., for MinIO) using Terraform dynamic blocks.

**Cloud-Init:** Standardizes user configuration (SSH keys, IP setup).

**Usage Example (in root main.tf):**
```hcl
module "k8s_cluster" {
  source   = "./modules/compute/vm"
  for_each = var.k8s_nodes  # Iterates through inventory

  vm_name     = each.key
  vmid        = each.value.vmid
  target_node = var.target_node
  # ...
}
```
## State Management (S3 Backend)
We migrated from local terraform.tfstate files to a Remote S3 Backend hosted on our internal MinIO server.

### How to Apply Changes
**Authentication:**  Ensure AWS secrets are loaded (via .zshrc / .bashrc or export).

```Bash
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
```
**Initialize:**

```Bash
terraform init
```
**Plan & Apply:**

```Bash
terraform plan
terraform apply
```