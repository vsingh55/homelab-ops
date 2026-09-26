# Infrastructure Modernization & Platform Execution Master Index

| Platform Parameter | Engineering Specification |
| :--- | :--- |
| **Physical Hardware** | Intel Core i5 Mini PC (4 Cores / 8 Threads, 16GB DDR4 RAM) |
| **Primary Storage** | Dual-Tier: 256GB NVMe PCIe Gen3 (Hot) + 1TB SATA HDD (Cold) |
| **Architecture Standard** | Single-Node Sovereign Cloud Platform (v3.0.0) |
| **Operating Model** | Multi-Cloud Hybrid Architecture (Proxmox VE, K3s, OCI Mumbai, Cloudflare Zero Trust) |
| **Operational Status** | Production Verified (100% Complete & Live) |

---

## 1. Executive Purpose & Strategic Transformation

This directory contains the canonical engineering execution records documenting the end-to-end architectural modernization of the `homelab-ops` platform. The objective of this multi-phase transformation was to eliminate hardware resource fragmentation, terminate recurring cloud egress and compute costs, and transition from an ad-hoc, multi-bastion lab into a high-performance, production-grade **Single-Node Sovereign Cloud**.

Each phase represents an isolated, mathematically budgeted milestone with explicit architectural rationale, configuration deliverables, failure modes, and verification gates.

---

## 2. Master Execution Phase Index

| Phase | Milestone Title | Primary Scope | Architectural Deliverable | Impact & Hardware Yield |
| :--- | :--- | :--- | :--- | :--- |
| **[01. Architecture Baseline](01-architecture-baseline.md)** | Baseline Architecture & Governance | Specification alignment, resource budgeting, and ADR synchronization | Formalized [ADR-001](../adr/README.md#adr-001), [ADR-015](../adr/README.md#adr-015), and [ADR-016](../adr/README.md#adr-016) | Mathematical budget locked; zero-drift baseline established |
| **[02. Codebase Pruning](02-codebase-pruning.md)** | Codebase Pruning & Inventory Restructuring | Purging obsolete lab definitions and intermediate bastion proxies | Pruned [infrastructure/on-prem/](file:///home/vsc/devlopment/myGH/homelab-ops/infrastructure/on-prem/) and simplified Ansible inventory | Reclaimed ~7.5GB defined RAM; eliminated bastion single point of failure |
| **[03. Remote State Migration](03-remote-state-migration.md)** | Multi-Cloud Remote State Backend Architecture | Migrating Terraform state off-premises to Oracle Cloud Infrastructure (OCI) | Configured S3-compatible backend in [infrastructure/on-prem/backend.tf](file:///home/vsc/devlopment/myGH/homelab-ops/infrastructure/on-prem/backend.tf) | Decoupled state from physical host; protected against bare-metal loss |
| **[04. Hypervisor Consolidation](04-proxmox-consolidation.md)** | Hypervisor Consolidation & K3s-Prod Resizing | VM decommissioning and production engine expansion on Proxmox VE | Resized `k3s-prod` (VM 500) to 12GB RAM / 4 vCPUs; mounted 1TB SATA HDD | Reclaimed 2GB RAM + 250GB virtual disk; dedicated 75% host RAM to K8s |
| **[05. Edge Ingress & Registry](05-edge-ingress-and-registry.md)** | Cloudflare Edge Ingress & Container Registry Decoupling | Edge Anycast routing and container image registry migration | Deployed [kubernetes/platform/cloudflared/](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/cloudflared/) and GitHub Container Registry | Latency reduced from ~500ms to <15ms; closed all WAN router ports |
| **[06. GitOps & SOPS Secrets](06-gitops-bootstrap-sops.md)** | Declarative GitOps Bootstrapping & In-Git Secrets | Pull-based continuous delivery and asymmetric secret encryption | Bootstrapped Flux CD v2 controller with Mozilla SOPS and Age encryption | True GitOps continuous delivery; zero config drift; cryptographic secret safety |
| **[07. Fleet Deployment & ChatOps](07-application-fleet-deployment.md)** | Workload Fleet Onboarding & Dual-Tier Storage | Production application deployment, database HA, and ChatOps | Deployed CloudNativePG HA, hardened n8n, media stack, and Uptime Kuma | 9 production services live; dual-tier storage active; automated Slack ChatOps |

---

## 3. Physical Hardware Resource Budget (16GB Host Fencing)

To guarantee host stability and prevent Linux Out-Of-Memory (OOM) killer panics, physical hardware resources are fenced with strict mathematical limits:

```
Physical Host RAM Budget (16,384 MB Total):
├── k3s-prod Virtual Machine (VM 500) : 12,288 MB (75.0%)
│   ├── Active Production Workloads  : ~3,500 MB – 4,200 MB (CloudNativePG, n8n, Media, Traefik)
│   └── Dynamic Headroom Buffer      : ~8,000 MB – 8,700 MB (OCR bursts, transcoding, backup compression)
├── Proxmox VE Hypervisor Reserve    :  3,500 MB (21.5%)
│   ├── Linux Kernel & Hypervisor    : ~1,500 MB
│   └── ZFS / ext4 ARC & vzdump Pool : ~2,000 MB
└── Emergency Unallocated Buffer     :    596 MB ( 3.5%)
```

---

## 4. Architectural Governance & Operating Principles

1. **Strict Phased Progression:** No infrastructure phase is initiated until the previous phase has passed all validation assertions.
2. **Zero Plaintext Secrets:** All sensitive credentials, tokens, and private keys must be encrypted at rest using Mozilla SOPS with Age keypairs before entering Git history.
3. **Pre-Destruction Snapshots:** Virtual machines and physical partitions must be snapshotted via Proxmox `vzdump` prior to any modification or deletion.
4. **Direct Zero-Trust Operations:** All administrative operations are executed directly from the engineer's workstation over the Tailscale WireGuard mesh, eliminating intermediate bastion proxies.
5. **Deterministic GitOps Reconciliation:** Cluster state is driven exclusively through Git commits to `origin/main` reconciled by Flux CD v2.
