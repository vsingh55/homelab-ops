# Phase 1: Baseline Architecture Synchronization & Hardware Budgeting

| Milestone Attribute | Engineering Specification |
| :--- | :--- |
| **Phase Scope** | Global Architecture Blueprint, Resource Budgeting & Governance |
| **Target Infrastructure** | Bare-Metal Host (16GB RAM Mini PC), Proxmox VE 8.x, K3s Kubernetes |
| **Primary Code Paths** | [`docs/architecture/`](../architecture/), [`docs/adr/`](../adr/) |
| **Relevant Decisions** | [ADR-001](../adr/README.md#adr-001), [ADR-015](../adr/README.md#adr-015), [ADR-016](../adr/README.md#adr-016) |
| **Operational Status** | Production Verified (Platform v3.0.0) |

---

## 1. Executive Summary & Objective

Phase 1 establishes the single, authoritative architectural blueprint and decision framework for the entire homelab modernization. In enterprise platform engineering, running systems are never altered or decommissioned until the target state is mathematically verified, hardware boundaries are established, and all trade-offs are formalized in **Architecture Decision Records (ADRs)**.

This phase guarantees that:
1. Every structural change is anchored in a formal ADR.
2. Contradictions between legacy documentation and target state (e.g., ArgoCD vs Flux CD, Keycloak vs Cloudflare Access) are purged.
3. Physical hardware resources (16GB RAM ceiling on the Mini PC) are strictly budgeted before resizing virtual machines.
4. Pre-flight connectivity across Proxmox, Tailscale, OCI, and Cloudflare is verified prior to touching code.

---

## 2. Problem Statement: Legacy Architecture Inefficiencies

Prior to this modernization, the platform suffered from three severe operational bottlenecks:

1. **The Academy Zone Fragmentation:** 5 virtual machines/LXCs (`gateway`, `jumpbox`, `server`, `node-0`, `node-1`) were running on the host, consuming ~7.5GB of defined RAM solely for historical Kubernetes certification labs. Because certification was complete, these resources sat idle.
2. **The `ops-center` Bastion Overhead:** A dedicated KVM virtual machine (2 vCPUs, 2GB RAM, 20GB NVMe, 250GB virtual disk) ran solely to host a Dockerized MinIO container (holding ~50KB of Terraform state) and act as an SSH jump proxy. This added latency and introduced a single point of failure.
3. **Cross-Atlantic Ingress Latency:** Public ingress routed through a legacy Google Cloud VM in South Carolina (`us-east1`) over WireGuard, adding ~500ms of round-trip latency for domestic Indian visitors and incurring unnecessary cloud compute charges.

---

## 3. Core Architectural Decisions

Before modifying any configuration files, the following 5 foundational decisions were locked into the architecture register:

| Decision | Legacy Baseline (v1.0 / v2.0) | Target Architecture (v3.0) | Impact & Rationale |
| :--- | :--- | :--- | :--- |
| **D1: Decommission Academy Zone** | 5 VMs/LXCs consuming ~7.5GB RAM | Completely purged from hypervisor and IaC definitions | Reclaimed **~7.5GB defined RAM** on the physical host ([ADR-016](../adr/README.md#adr-016)). |
| **D2: Terminate `ops-center` Bastion** | 2GB KVM VM hosting MinIO and SSH proxy | Eliminated; Terraform state moved to OCI Mumbai Object Storage | Reclaimed **2GB RAM, 2 vCPUs, 20GB NVMe, 250GB disk** ([ADR-015](../adr/README.md#adr-015)). |
| **D3: Resize `k3s-prod`** | 8GB RAM, 2 vCPUs, 30GB disk | Resized to **12GB RAM, 4 vCPUs**, with direct **1TB SATA HDD** mount | Delivers >60% memory headroom (~8.3GB buffer) for OCR and media processing. |
| **D4: Direct Administrative Access** | Dual-hop SSH proxy via `ops-center` | Direct execution from engineer laptop via Tailscale WireGuard mesh | Cuts execution latency in half; removes bastion single point of failure ([ADR-005](../adr/README.md#adr-005)). |
| **D5: Edge Anycast Ingress** | GCP VM gateway in `us-east1` (~500ms latency) | **Cloudflare Zero Trust Tunnels (`cloudflared`)** terminating in India | Latency dropped to **<15ms**; closed all inbound router ports ([ADR-006](../adr/README.md#adr-006)). |

---

## 4. Hardware Resource Budget & Mathematical Verification

On a single physical node with 16GB RAM, over-allocating memory leads to aggressive swap thrashing or Linux kernel panics. The allocation formula is strictly budgeted:

$$\text{RAM}_{\text{Host}} = 16,384\text{ MB (16.0 GB)}$$

$$\text{RAM}_{\text{Allocated}} = \text{k3s-prod (12,288 MB)} + \text{Proxmox Reserve (3,500 MB)} = 15,788\text{ MB (15.42 GB)}$$

$$\text{Buffer}_{\text{Safety}} = 16,384\text{ MB} - 15,788\text{ MB} = 596\text{ MB (3.6%) Unallocated Headroom}$$

This mathematical fencing guarantees that:

- Proxmox has sufficient unswappable memory for ZFS ARC, kernel buffers, and `vzdump` backup compression.
- `k3s-prod` has 12GB dedicated RAM, of which only ~3.5GB–4.2GB is consumed by active services, leaving ~8GB of dynamic burst capacity for document OCR and database operations.

---

## 5. Pre-Flight Verification & External Readiness

Before proceeding to Phase 2 (code pruning) and Phase 3 (state migration), all external dependencies and connectivity channels were audited:

### 1. Tailscale Hypervisor Access
```bash
# Verify direct API reachability to Proxmox VE over Tailscale (100.108.178.93)
curl -k -s -o /dev/null -w "%{http_code}\n" https://100.108.178.93:8006/api2/json
# Expected result: 200 or 401 (API service responding directly without bastion)
```

### 2. Direct Node Connectivity
```bash
# Verify direct SSH connectivity to k3s-prod
ssh -o ConnectTimeout=5 -o BatchMode=yes devops@192.168.1.30 "uname -a"
```

### 3. Oracle Cloud Infrastructure (OCI) Credentials
- Generated OCI Customer Secret Key for S3-compatible Object Storage access in region `ap-mumbai-1`.
- Retrieved tenancy Object Storage Namespace to construct standard S3 endpoints for Terraform state.

### 4. Authoritative DNS & Domain Delegation
- Verified authoritative DNS for `vijaysingh.cloud` is active on Cloudflare Anycast edge nameservers.
- Confirmed independent Cloudflare Pages sites operate normally and are decoupled from the homelab infrastructure.

---

## 6. Exit Gate & Phase Transition

The completion of Phase 1 establishes the single source of truth for the platform. With architectural consensus locked in ADRs, hardware allocations mathematically bounded, and external access verified, the platform transitioned directly to **[Phase 2: Codebase Pruning & Inventory Restructuring](02-codebase-pruning.md)**.
