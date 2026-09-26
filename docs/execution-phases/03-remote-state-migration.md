# Phase 3: Multi-Cloud Remote State Backend Architecture

| Milestone Attribute | Engineering Specification |
| :--- | :--- |
| **Phase Scope** | Offsite Remote State Storage, State Locking & Disaster Resilience |
| **Target Infrastructure** | Oracle Cloud Infrastructure (OCI) Mumbai (`ap-mumbai-1`), Terraform S3 Backend |
| **Primary Code Paths** | [`infrastructure/on-prem/backend.tf`](file:///home/vsc/devlopment/myGH/homelab-ops/infrastructure/on-prem/backend.tf) |
| **Relevant Decisions** | [ADR-011](../adr/README.md#adr-011), [ADR-015](../adr/README.md#adr-015) |
| **Operational Status** | Production Verified (Platform v3.0.0) |

---

## 1. Executive Summary & Objective

Phase 3 establishes an offsite, high-availability, state-locked **S3-compatible remote backend** for all on-premises Terraform state using **Oracle Cloud Infrastructure (OCI) Object Storage** in the Mumbai region (`ap-mumbai-1`).

Migrating state to an offsite cloud provider decouples Terraform state survival from the physical Mini PC hardware. Once completed:
1. Terraform state is protected against local hardware loss (bare-metal drive failure, physical damage).
2. The local `ops-center` VM running MinIO is decoupled and prepared for permanent decommission (Phase 4).
3. The platform leverages edge-adjacent enterprise object storage with sub-20ms round-trip latency.

---

## 2. Engineering Rationale: Disaster Recovery & Decoupling

### A. The Co-Location Failure Mode
Previously, Terraform state was stored in a Dockerized MinIO container running on `ops-center` on the Mini PC's internal SATA hard drive:

- **Catastrophic Failure:** If the Mini PC suffered a physical drive or board failure, the state file perished with the hardware. Rebuilding infrastructure required manually reverse-engineering and importing dozens of Proxmox resources.
- **The Circular Dependency:** A team cannot use Terraform to provision or recover a hypervisor if Terraform's own state backend lives inside a virtual machine on that same hypervisor.

### B. Enterprise Multi-Cloud Resilience via OCI Object Storage
- **Standard S3 Protocol Compatibility:** OCI Object Storage provides an Amazon S3-compatible API endpoint, allowing standard Terraform `backend "s3"` blocks without proprietary vendor plugins.
- **Geographic Proximity:** Located in Mumbai (`ap-mumbai-1`), state read/write operations execute in sub-20ms over domestic broadband.
- **Native Versioning & Durability:** Object versioning ensures every state push creates an immutable historical version, enabling deterministic point-in-time state recovery.

---

## 3. Remote State Architecture

```
Architecture Flow:
[ Engineer Laptop (Workstation) ]
       │
       │ HTTPS S3 API (Port 443 / TLS 1.3)
       ▼
[ Oracle Cloud Infrastructure (OCI Mumbai ap-mumbai-1) ]
       ├── Bucket: homelab-terraform-state (Standard Storage Tier)
       ├── Object: on-prem/terraform.tfstate
       ├── Security: OCI Customer Secret Key (HMAC / SHA-256)
       └── Durability: Native Object Versioning Active
```

---

## 4. Technical Execution Details

### 1. Pre-Flight State Snapshot (Safety Gate)
Before modifying the backend definition, a dated local snapshot of the active state was secured:

```bash
mkdir -p ~/homelab-backups/terraform-state
cd infrastructure/on-prem

# Pull active state to an unmanaged local archive
terraform state pull > ~/homelab-backups/terraform-state/terraform.tfstate.pre-migration.$(date +%Y%m%d)
```

### 2. OCI S3 Endpoint Configuration
The on-premises backend was configured in `infrastructure/on-prem/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "on-prem/terraform.tfstate"
    region                      = "ap-mumbai-1"
    endpoint                    = "https://<OCI_NAMESPACE>.compat.objectstorage.ap-mumbai-1.oraclecloud.com"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}
```

### 3. State Migration Execution
With OCI Customer Secret credentials exported in the administrative environment, Terraform was reinitialized with state migration enabled:

```bash
cd infrastructure/on-prem

export AWS_ACCESS_KEY_ID="<OCI_CUSTOMER_ACCESS_KEY>"
read -sp "Enter OCI Secret Key: " AWS_SECRET_ACCESS_KEY && export AWS_SECRET_ACCESS_KEY

terraform init -migrate-state
```

When prompted, input `yes` to transfer state objects from local storage to OCI Object Storage.

---

## 5. Verification & State Integrity Assertions

### 1. Remote State Inventory Verification
```bash
cd infrastructure/on-prem
terraform state list
# Output: Returns the active module.k3s_prod resources fetched directly from OCI.
```

### 2. Zero-Diff Plan Execution
```bash
terraform plan
# Output: No changes. Your infrastructure matches the configuration.
```

### 3. Cloud Storage Confirmation
In the OCI Console under Object Storage (`ap-mumbai-1`), verified that object `on-prem/terraform.tfstate` exists with versioning active and encrypted under Oracle-managed keys.

---

## 6. Exit Gate & Phase Transition

With Terraform state securely stored off-premises and decoupled from the local hypervisor, the platform satisfied all safety prerequisites to proceed to **[Phase 4: Hypervisor Consolidation & K3s-Prod Resizing](04-proxmox-consolidation.md)**.
