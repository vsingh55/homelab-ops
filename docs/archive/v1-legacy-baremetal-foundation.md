# Milestone v1.0: The Bare-Metal Proxmox Foundation (Legacy)

> **Status:** Historical Milestone (Superseded by Sovereign Cloud v3.0)  
> **Original Timeframe:** Milestone v1.0 Architecture  
> **Hardware:** Intel Core i5 Mini PC (16GB RAM, 256GB SSD, 1TB HDD)  

---

## 1. Context & Early Objectives

In the initial phase of the homelab, the objective was establishing a virtualization layer on bare-metal hardware and experimenting with logical zoning.

### The Initial Resource Budget
* **Host Hypervisor:** Proxmox VE installed directly on bare metal.
* **Storage Configuration:**
  - `local-lvm` (NVMe SSD): Allocated for base OS and container storage.
  - `HDD-Storage` (1TB SATA mechanical drive): Configured for ISO images and backup storage.
* **Early Logical Zoning:**
  - **Zone A (Production):** Early experiments using lightweight LXC containers for gateway, DNS, and IAM services.
  - **Zone B (Academy):** Ephemeral virtual machines dedicated to "Kubernetes The Hard Way" certification labs.

---

## 2. Legacy Architecture Topology

![v1 Architecture](../images/v.1.0.0/HomeLab-Ops%20V1.0.0.svg)

---

## 3. Pain Points & Why It Was Refactored

1. **Carrier-Grade NAT Isolation:** The cluster was isolated behind a home router with no external access, preventing public webhook ingestion.
2. **Resource Fragmentation:** Running multiple separate VMs and LXC containers for lab and management created excessive memory fragmentation, consuming ~7.5GB of RAM in idle definitions.
3. **Storage Misalignment:** Early backup snapshots filled the root SSD partition before the secondary HDD was properly partitioned.

*These limitations directly triggered the architectural evolution toward Phase 2 (Hybrid Cloud Bridge) and subsequently Phase 4 (Proxmox Host Consolidation).*
