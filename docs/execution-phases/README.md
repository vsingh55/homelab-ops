# Homelab Modernization & Hardware Optimization Execution Master Index

> **Architecture Standard:** Lean Sovereign Cloud Architecture (v2.0)  
> **Hardware Target:** 16GB RAM Mini PC (Intel Core i5, 256GB NVMe SSD, 1TB SATA mechanical HDD)  
> **Author / Role:** Principal Architect / Homelab Platform Team  
> **Repository:** `https://github.com/vsingh55/homelab-ops`  
> **Baseline References:** [`blueprint.md`](file:///home/vsc/devlopment/myGH/homelab-ops/blueprint.md), [`current vs future.md`](file:///home/vsc/devlopment/myGH/homelab-ops/current%20vs%20future.md), and [`process/architecture_decision_records.md`](file:///home/vsc/devlopment/myGH/homelab-ops/process/architecture_decision_records.md).

---

## 1. Executive Purpose

This directory contains the exhaustive, phase-by-phase execution manuals for transforming `homelab-ops` from a high-latency, multi-bastion, resource-fragmented lab into an optimized, production-grade **Single-Node Sovereign Cloud**.

Each document in this directory corresponds to a discrete implementation phase defined in the master Implementation Plan. Every phase provides complete clarity across:
1. **The "Why":** Deep architectural rationale, hardware economics, and trade-off analysis.
2. **The "What":** Concrete file deliverables, resource state definitions, and deleted components.
3. **The "How":** Exact commands, configuration code snippets, execution sequences, and scripts.
4. **Safety & Rollback:** Pre-flight verification, failure modes, and deterministic rollback plans.
5. **Validation:** Fitness functions and verification checks confirming that the phase succeeded.

---

## 2. Master Execution Phase Index

| Phase Document | Primary Focus | Key Architectural Impact | Hardware / Financial Impact |
| :--- | :--- | :--- | :--- |
| **[01-phase-1-architecture-baseline.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/01-phase-1-architecture-baseline.md)** | Documentation & ADR Baseline Synchronization | Establishes SSOT across Blueprint, Comparison Matrix, and ADRs (ADR-015, ADR-016) | Conceptual alignment; zero risk |
| **[02-phase-2-codebase-pruning.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/02-phase-2-codebase-pruning.md)** | Academy Zone & Ops-Center Config Purge | Purges obsolete lab Terraform modules, Ansible playbooks, and inventory groups | Reclaims ~7.5GB defined RAM; simplifies inventory |
| **[03-phase-3-oci-remote-state.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/03-phase-3-oci-remote-state.md)** | Offsite State Backend Migration | Migrates Terraform state from local MinIO to Oracle Cloud Always Free Object Storage in Mumbai | Offsite durability; decouples state from Mini PC; ₹0.00 cost |
| **[04-phase-4-proxmox-consolidation-k3s-resizing.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/04-phase-4-proxmox-consolidation-k3s-resizing.md)** | Host Consolidation & K3s-Prod 12GB Resizing | Destroys 5 lab VMs and `ops-center` VM on Proxmox; expands `k3s-prod` to 12GB RAM / 4 vCPUs; attaches 1TB HDD | Reclaims 2GB RAM + 20GB NVMe + 250GB virtual disk; dedicates 12GB to K3s |
| **[05-phase-5-gcp-decommissioning-cloudflare-ingress.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/05-phase-5-gcp-decommissioning-cloudflare-ingress.md)** | Cloud Cost Elimination & Edge Tunnels | Destroys GCP VM gateway & IP; deploys `cloudflared` for Anycast edge routing; migrates to GHCR | Saves ~$10/month; cuts latency from 500ms to <15ms; ₹0.00 cloud spend |
| **[06-phase-6-gitops-bootstrap-sops.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/06-phase-6-gitops-bootstrap-sops.md)** | GitOps Engine & In-Git Secrets | Bootstraps Flux CD v2 controller in K3s; sets up Mozilla SOPS with Age master key | Pull-based GitOps; zero config drift; cryptographic secret safety |
| **[07-phase-7-application-fleet-deployment.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/07-phase-7-application-fleet-deployment.md)** | Workload Fleet Onboarding & Verification | Deploys CloudNativePG HA, hardened n8n, 2 websites, BookOrbit, Paperless on 1TB HDD, Uptime Kuma | 9 production apps + 2 public websites live; true 3-2-1 backup active |

---

## 3. Global Execution Principles & Operational Rules

1. **Strict Phasing Order:** Do not execute Phase $N+1$ until Phase $N$ has met all validation criteria.
2. **Zero Plaintext Secrets:** Under no circumstances should unencrypted tokens, private keys, or passwords be committed to Git.
3. **Backup Before Destruction:** Always verify that state files, database dumps, and critical data are securely snapshotted before deleting virtual machines or storage volumes.
4. **Idempotency:** All playbooks, manifests, and Terraform definitions must be re-runnable without unintended side-effects.
5. **No Intermediate Bastions:** Operating commands must be executed directly from the engineer's laptop over Tailscale.
