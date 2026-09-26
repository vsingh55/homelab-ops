# Engineering Retrospective: Monolithic-to-Modular Terraform Infrastructure Architecture

> **Platform Standard:** Historical Infrastructure as Code (IaC) Architecture  
> **Milestone Era:** Milestone v2.0 Architecture  
> **Status:** Archival Reference (Foundation for modern multi-cloud state)  

---

## Executive Overview

| Attribute | Specification |
| :--- | :--- |
| **Domain** | Declarative Infrastructure as Code (IaC) & State Architecture |
| **Target Infrastructure** | Bare-Metal Proxmox VE 8.x Hypervisor & Cloud Compute Instances |
| **Tooling Adopted** | Terraform v1.5+, HCL Dynamic Blocks, MinIO S3 Remote Backend, Telmate Provider |
| **Lead Engineer** | Vijay Singh (Platform & DevOps Engineer) |
| **Key Outcome** | Eliminated 100% of duplicated HCL boilerplate; enabled dynamic multi-disk provisioning and remote state concurrency locking |

---

## 1. The Architectural Impasse: Monolithic `main.tf` Debt

In the early stages of the homelab, all virtual machines and hypervisor settings were declared in a single, monolithic `main.tf` file exceeding 800 lines of HCL. This structure introduced severe technical friction:

1. **Massive Code Duplication:** Declaring `node-0`, `node-1`, and `server` required copying the exact same 45-line `proxmox_vm_qemu` resource block repeatedly, violating the "Don't Repeat Yourself" (DRY) principle.
2. **Schema Rigidity:** If a single virtual machine (such as `ops-center`) required a secondary 250GB backup mechanical disk while the remaining nodes only required NVMe root storage, the monolithic resource block could not adapt without ugly conditional hacks.
3. **Concurrency & State Collision Risk:** Local `terraform.tfstate` files committed locally or shared over ad-hoc file sync risked state corruption and race conditions if modified simultaneously.

---

## 2. Modular Architecture Design

To resolve duplication and decouple infrastructure intent from implementation, the codebase was decomposed into reusable, parameterized modules:

```text
infrastructure/on-prem/
├── main.tf                    # Root composition orchestrating module calls
├── variables.tf               # Global input variable definitions
├── outputs.tf                 # Global outputs (IP addresses, VM IDs)
├── terraform.tf               # Provider versions and S3 remote backend config
│
├── modules/
│   ├── compute/
│   │   ├── vm/                # Standardized QEMU Virtual Machine Blueprint
│   │   │   ├── main.tf        # Core proxmox_vm_qemu resource & Cloud-Init
│   │   │   ├── variables.tf   # Module inputs (memory, cores, disks)
│   │   │   └── outputs.tf     # Computed IP and MAC addresses
│   │   │
│   │   └── lxc/               # Standardized LXC Container Blueprint
│   │       ├── main.tf
│   │       └── variables.tf
│   │
│   └── storage/               # Storage pool mapping and volume definitions
```

### Key Technical Innovation: Dynamic Storage Allocation
To allow arbitrary nodes to attach secondary bulk storage without modifying the underlying module, HCL `dynamic` blocks were engineered:

```hcl
# modules/compute/vm/main.tf
dynamic "scsi" {
  for_each = var.secondary_disk_size != "0G" ? [1] : []
  content {
    scsi1 {
      disk {
        storage = var.secondary_disk_storage
        size    = var.secondary_disk_size
        format  = "raw"
      }
    }
  }
}
```

If `secondary_disk_size` is left at default `"0G"`, the loop evaluates to an empty list `[]` and no secondary disk is synthesized. If specified (e.g. `"250G"`), Terraform conditionally creates and attaches the secondary SCSI drive seamlessly.

---

## 3. Engineering Challenges & Forensic Debugging

### Challenge 1: The "Ghost Drift" in Proxmox Tags
**Symptom:** Running `terraform plan` persistently detected phantom changes on the `tags` parameter, attempting to replace a space string `" "` with `null` on every single execution.

**Root Cause:** The Proxmox VE API stored empty tags internally as an ASCII whitespace character (`" "`). When Terraform compared this to an omitted or `null` tag in HCL, it registered state drift.

**Remediation:** Executed a one-time targeted update applying an explicit empty string tag, forcing the provider to align state metadata with the upstream API.

### Challenge 2: State Loss During MinIO Storage Migration
**Symptom:** After relocating MinIO's data directory to the secondary SATA mechanical drive, `terraform plan` reported that all 6 infrastructure resources had vanished and proposed re-creating the entire homelab from scratch.

**Root Cause:** The MinIO container was re-bound to an empty filesystem mount (`/mnt/storage/minio-data`), while the actual `terraform.tfstate` binary resided on the old unmounted volume.

**Remediation:**
1. Halted Terraform execution immediately to prevent disaster.
2. Mounted the historical volume, extracted `terraform.tfstate`, and verified JSON checksums.
3. Seeded the state file into the new MinIO S3 bucket and executed `terraform state list` to confirm 100% resource match.

### Challenge 3: VM Lifecycle Wars (`onboot` vs `vm_state`)
**Symptom:** Terraform repeatedly attempted to power on stopped lab VMs even though `onboot = false` was configured.

**Root Cause:** By default, the `proxmox_vm_qemu` provider enforces a running container state. Setting `onboot = false` only instructs Proxmox not to start the VM on hypervisor reboot; it does not tell Terraform to leave the VM powered off.

**Remediation:** Directly tied the `vm_state` attribute to the operational variable in HCL:

```hcl
# modules/compute/vm/main.tf
vm_state = var.onboot ? "running" : "stopped"
```

---

## 4. Remote State Architecture: Local to S3 Backend

State management was upgraded from fragile local files to an S3-compatible remote backend hosted on MinIO with distributed state locking:

```hcl
# terraform.tf
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "homelab/on-prem/terraform.tfstate"
    endpoint                    = "http://100.108.178.93:9000"
    region                      = "main"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
```

---

## 5. Standard Operating Procedure: Safe Execution

To prevent credential leakage while maintaining automated workflows, credentials must never be hardcoded into configuration files:

```bash
# 1. Interactively export remote backend credentials
export AWS_ACCESS_KEY_ID="<MINIO_ACCESS_KEY>"
read -sp "Enter S3 Secret Key: " AWS_SECRET_ACCESS_KEY && export AWS_SECRET_ACCESS_KEY

# 2. Initialize modules and remote state backend
terraform init

# 3. Generate and inspect execution plan
terraform plan -out=tfplan.binary

# 4. Apply approved infrastructure changes
terraform apply tfplan.binary
```

---

## 6. Architectural Evolution to Milestone v3.0

The modularization of Terraform provided the foundation for **Phase 3 (Remote State Migration to OCI S3)** and **Phase 4 (Hypervisor Consolidation)** in Milestone v3.0:

- **State Portability:** The S3 backend architecture cleanly transitioned from internal MinIO to enterprise-grade **Oracle Cloud Infrastructure (OCI) Object Storage** with zero downtime.
- **Node Consolidation:** The flexible module architecture allowed collapsing multiple disparate VMs into a single, high-efficiency production Kubernetes node (`k3s-prod`), drastically optimizing resource utilization.