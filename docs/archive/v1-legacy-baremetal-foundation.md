# Milestone v1.0: Bare-Metal Hypervisor Foundation & LXC Zoning (Legacy)

> **Platform Standard:** Historical Architectural Baseline  
> **Status:** Deprecated (Superseded by Sovereign Cloud v3.0)  
> **Original Timeframe:** Milestone v1.0 Architecture  
> **Physical Hardware:** Intel Core i5 Mini PC (16GB RAM, 256GB SSD, 1TB HDD)  

---

## 1. Context & Early Objectives

In the initial iteration of the homelab, the primary objective was establishing a robust virtualization layer directly on bare-metal hardware and experimenting with workload isolation, storage partitioning, and hypervisor resource management.

### Initial Resource Allocation

| Layer / Zone | Physical / Virtual Host | Resource Allocation | Storage Pool Bound | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Hypervisor Base** | Proxmox VE 8 (Host OS) | 4GB RAM, 4 vCPUs | 256GB NVMe (`pve-root`) | Core KVM hypervisor daemons, bridge networking, and local storage pools. |
| **Zone A (Production)** | LXC Containers & VMs | 6GB RAM, 2 vCPUs | NVMe (`local-lvm`) | Early lightweight services: DNS (Pi-hole), local Nginx reverse proxy, and identity experiments. |
| **Zone B (Academy)** | Ephemeral Lab VMs | 6GB RAM, 2 vCPUs | NVMe (`local-lvm`) | Certification practice sandboxes and "Kubernetes The Hard Way" lab clusters. |
| **Secondary Disk** | Physical 1TB SATA HDD | Raw Mount (`/mnt/hdd`) | `HDD-Storage` (ext4) | Dedicated target for ISO installer images and VM snapshots. |

---

## 2. Legacy Architecture Topology

![v1 Architecture](../images/v.1.0.0/HomeLab-Ops%20V1.0.0.svg)

---

## 3. Architectural Deficits & Pain Points

Operating Milestone v1.0 in a production homelab environment revealed critical systemic limitations:

1. **Carrier-Grade NAT (CGNAT) Isolation:**
   - The residential ISP assigned private non-routable IPv4 addresses.
   - Traditional router port forwarding was technically impossible.
   - External webhooks from GitHub, Stripe, or alert systems could not reach internal containers without opening insecure holes.

2. **Severe RAM & Resource Fragmentation:**
   - Partitioning a 16GB host across multiple discrete VMs and LXC containers introduced substantial OS memory overhead.
   - Idle Linux kernels and container runtime daemons consumed ~7.5GB of RAM before application workloads even started.

3. **Storage Contention & Snapshot Failure:**
   - Early unconstrained VM snapshots filled the primary NVMe root partition before automated storage policy routing was implemented, causing hypervisor lockups.

4. **Configuration Drift:**
   - Systems were configured using manual shell commands and localized bash scripts without version control or idempotency guarantees.

---

## 4. Key Learnings & Catalyst for Modernization

- **Lesson 1 (Consolidation):** Rather than running multiple competing VMs on limited memory, consolidating workloads onto a single production Kubernetes node (`k3s-prod`) eliminates hypervisor fragmentation.
- **Lesson 2 (Infrastructure as Code):** Manual configuration is technical debt. All future provisioning was mandated to use Terraform and Ansible.
- **Lesson 3 (Edge Traversal):** Overcoming residential CGNAT requires an active edge traversal mechanism rather than local router tampering.

*These pain points directly catalyzed the development of Milestone v2.0 (Hybrid Cloud Relay) and the subsequent Sovereign Cloud v3.0 architecture.*
