# Homelab-Ops: Enterprise Architecture Decision Records (ADR)
## Modernization Blueprint & Sovereign Cloud Architecture

> **Document Version:** 1.0.0 
> **Author / Role:** Principal Architect / CTO 
> **Date:** September 2026 
> **Repository:** `https://github.com/vsingh55/homelab-ops` 
> **Target Architecture:** Production Sovereign Cloud Reference Standard 
> **Status:** Production Reference Architecture

---

## Table of Contents
1. [Executive Architecture Summary](#1-executive-architecture-summary)
2. [Current Architecture Overview](#2-current-architecture-overview)
3. [Architectural Decision Inventory](#3-architectural-decision-inventory)
4. [Missing / Undocumented Decisions](#4-missing--undocumented-decisions)
5. [Architectural Risks and Smells](#5-architectural-risks-and-smells)
6. [ADR Priority Matrix](#6-adr-priority-matrix)
7. [Comprehensive Architecture Decision Records](#7-comprehensive-architecture-decision-records)

- [ADR-001: Bare-Metal Virtualization via Proxmox VE with Isolated Logical Zones](#adr-001-bare-metal-virtualization-via-proxmox-ve-with-isolated-logical-zones)
- [ADR-002: Dual-Tier Storage Topology (Hot NVMe vs. Cold SATA HDD)](#adr-002-dual-tier-storage-topology-hot-nvme-vs-cold-sata-hdd)
- [ADR-003: Public Ingress via Cloud VM & WireGuard Site-to-Site Tunnel](#adr-003-public-ingress-via-cloud-vm--wireguard-site-to-site-tunnel)
- [ADR-004: In-Memory "Vault Hydration" Pattern for Bare-Metal Infrastructure Secrets](#adr-004-in-memory-vault-hydration-pattern-for-bare-metal-infrastructure-secrets)
- [ADR-005: Out-of-Band Administrative Access via Tailscale Mesh Overlay](#adr-005-out-of-band-administrative-access-via-tailscale-mesh-overlay)
- [ADR-006: Ingress Modernization: Migration from Cloud VM / WireGuard to Cloudflare Zero Trust Tunnels](#adr-006-ingress-modernization-migration-from-cloud-vm--wireguard-to-cloudflare-zero-trust-tunnels)
- [ADR-007: Pull-Based GitOps Continuous Delivery via Flux CD v2 with Trunk-Based Directory Overlays](#adr-007-pull-based-gitops-continuous-delivery-via-flux-cd-v2-with-trunk-based-directory-overlays)
- [ADR-008: Declarative In-Git Secrets Management via Mozilla SOPS and Age Encryption](#adr-008-declarative-in-git-secrets-management-via-mozilla-sops-and-age-encryption)
- [ADR-009: Workload Hardening & Remediation Decoupling for Automation Engines (Elimination of `hostNetwork`, Root Privileges, and In-Pod SSH Access)](#adr-009-workload-hardening--remediation-decoupling-for-automation-engines)
- [ADR-010: Database Modernization: Migration from Standalone PostgreSQL Pod to CloudNativePG HA Operator](#adr-010-database-modernization-migration-from-standalone-postgresql-pod-to-cloudnativepg-ha-operator)
- [ADR-011: Multi-Cloud Hybrid Resilience: OCI Mumbai Support Plane for Out-of-Band Monitoring (Uptime Kuma) and Offsite Disaster Recovery](#adr-011-zero-cost-cloud-extension-oci-always-free-mumbai-for-out-of-band-monitoring-and-offsite-restic-backup-sync)
- [ADR-012: Hybrid Zero-Trust Identity Architecture: Cloudflare Access (SSO/MFA) for Web Applications and Tailscale for Host Infrastructure](#adr-012-hybrid-zero-trust-identity-architecture-cloudflare-access-for-web-applications-and-tailscale-for-host-infrastructure)
- [ADR-013: Sovereign Document & Media Storage Tiering Strategy on 1TB HDD for Paperless-ngx, BookOrbit, and Audiobookshelf](#adr-013-sovereign-document--media-storage-tiering-strategy-on-1tb-hdd)
- [ADR-014: Progressive Delivery Scoping: Deferral of Canary Deployments for Single-Replica Workloads](#adr-014-progressive-delivery-scoping-deferral-of-canary-deployments-for-single-replica-workloads)
- [ADR-015: Decommissioning of ops-center VM in Favor of OCI S3 Remote State and Direct Laptop Operations](#adr-015-decommissioning-of-ops-center-vm-in-favor-of-oci-s3-remote-state-and-direct-laptop-operations)
- [ADR-016: Complete Decommissioning and Code Purge of the Academy / Lab Zone Post-Certification](#adr-016-complete-decommissioning-and-code-purge-of-the-academy--lab-zone-post-certification)

---

## 1. Executive Architecture Summary

### System Purpose
The `homelab-ops` platform is a production-grade, self-hosted **Sovereign Cloud** engineered to provide enterprise-standard digital services, portfolio hosting, workflow automation, document management, and private cloud infrastructure while operating under strict real-world constraints:
1. **Zero Recurring Infrastructure Cost:** Eliminating ongoing cloud subscriptions in favor of owned on-premises hardware supplemented by validated cost-optimized multi-cloud hybrid architecture (OCI & GCP).
2. **Data Sovereignty & Privacy:** Retaining sensitive documents (Paperless-ngx), personal automation workflows (n8n), digital reading libraries (BookOrbit), and database assets on privately controlled hardware.
3. **Zero Trust & CGNAT Traversal:** Securely accepting external webhooks and public visitors without exposing home network ports or violating residential ISP constraints.
4. **Resilient GitOps Operations:** Operating an automated, declarative infrastructure lifecycle using CNCF-standard GitOps continuous delivery, immutable state versioning, and an unbreakable 3-2-1 backup topology.

### Major Components
- **Hardware Layer:** Single Mini PC node (Intel i5, 16GB DDR4 RAM, 256GB NVMe SSD, 1TB SATA HDD).
- **Hypervisor Plane:** Proxmox VE 9.x managing Type-1 hypervisor virtualization, hardware resource fencing, and virtual storage pools (~3.5GB RAM reserved for host).
- **Operations Control Plane (Laptop):** Engineer's Laptop executing Ansible playbooks and Terraform commands directly via Tailscale (zero intermediate bastion hops).
- **Production Kubernetes Plane (`k3s-prod`):** K3s lightweight Kubernetes cluster (VM 500, expanded to **12GB RAM / 4 vCPUs**) hosting all production application workloads.
- **Public Edge Layer:** Transitioning from an un-optimized GCP Compute Engine gateway in South Carolina (`us-east1`) running WireGuard and Nginx to **Cloudflare Zero Trust Anycast Edge Tunnels (`cloudflared`)** connecting to Indian edge PoPs (Mumbai, Delhi, Chennai).
- **Out-of-Band Cloud Extension:** Oracle Cloud Infrastructure (OCI) support instance in Mumbai (`ap-mumbai-1`) hosting Uptime Kuma external health probes, **Terraform remote S3 state backend**, and an offsite encrypted Restic backup target.
- **Application Fleet:** 
- *Public Web:* Homelab Architecture Docs (`docs.vijaysingh.cloud`).
- *Productivity & Core:* Homepage dashboard, Miniflux RSS engine, Linkding bookmark manager.
- *Data & Media:* Paperless-ngx OCR archive, BookOrbit multi-user library, Audiobookshelf media streaming.
- *Automation & DB:* n8n workflow engine, CloudNativePG (CNPG) High-Availability PostgreSQL operator.
- *Observability:* Kube-Prometheus-Stack (internal metrics) and Uptime Kuma (external availability).

### Major Data Flows
1. **Public Ingress Flow (Future):** External Visitor / Webhook -> Cloudflare Global Edge (Anycast DNS, Edge SSL, DDoS Shield, CDN cache) -> Outbound QUIC/HTTPS Tunnel -> In-cluster `cloudflared` daemon -> Traefik Ingress Controller -> Workload Pod (e.g. n8n, Website, BookOrbit).
2. **Administrative Control Flow:** Remote Engineer (Laptop) -> Tailscale Encrypted Mesh (WireGuard overlay `100.x.x.x`) -> Direct Proxmox Hypervisor (Port 8006) / Direct `k3s-prod` SSH (Port 22).
3. **Continuous Delivery Flow:** Git Push to GitHub `main` -> GitHub Actions CI Gate (Lint, Kubeconform, Trivy scan, Cosign) -> In-cluster Flux CD v2 Controller reconciles manifests -> SOPS decrypts Age-encrypted secrets in-memory -> Kubernetes updates live state -> Slack notification dispatched.
4. **Data Persistence & Disaster Recovery Flow:** Active transactional data written to NVMe -> CloudNativePG continuously streams WAL logs to in-cluster S3 on 1TB HDD -> Nightly encrypted Restic job synchronizes database dumps, configurations, and document assets to OCI Mumbai Object Storage (Offsite).

### Critical Dependencies
- Cloudflare Edge Network (DNS, Tunnels, Zero Trust Access).
- Residential Power & ISP Connectivity (Fiber WAN behind CGNAT).
- Local Mini PC Hardware (CPU/RAM thermal headroom, single-point-of-failure node).
- GitHub Infrastructure (Source of Truth repository, GitHub Container Registry, GitHub Actions CI).
- Oracle Cloud regional availability in `ap-mumbai-1`.

### Current Architecture Style
**Hybrid Edge-Distributed Sovereign Monocluster:** A hybrid cloud architecture pairing an on-premises single-node hypervisor and container orchestrator with distributed serverless edge networking and a satellite cloud observer.

### Important Architectural Boundaries
1. **Edge vs. On-Prem Ingress Boundary:** Demarcated by the Cloudflare Tunnel daemon (`cloudflared`), terminating public internet exposure and initiating internal private network routing.
2. **Management vs. Workload Boundary:** Hard separation between Proxmox hypervisor (`pve`) and `k3s-prod` (containerized application plane).
3. **Public Exposure vs. Zero Trust Access Boundary:** Public domains (`docs.*`, `hooks.*`) permit anonymous edge traffic; private management interfaces (`dash.*`, `books.*`, `docs-ocr.*`) are gated by Cloudflare Access MFA (Google SSO / Email OTP).
4. **Storage Tier Boundary:** Hot I/O tier (NVMe SSD: OS, etcd/K3s state, active database tables) versus Cold capacity tier (SATA HDD: backups, media libraries, documents).

### Major Risks & Technical Constraints
- **Hardware Single Point of Failure (SPOF):** Total loss of the Mini PC halts all local compute, database, and application services.
- **Resource Sizing Headroom:** Running Proxmox base (3.5GB) and `k3s-prod` (12GB) optimizes the 16GB ceiling, leaving ~8GB free headroom inside K3s for application bursts.
- **Automation Security Exposure:** The existing n8n deployment mounts host SSH keys, runs with `hostNetwork: true`, and executes arbitrary shell commands on bare-metal infrastructure (remediated under ADR-009).
- **Lack of Offsite Disaster Recovery:** Current backup snapshots are co-located on the same physical chassis (1TB HDD), remediated under ADR-011 via OCI Mumbai.

---

## 2. Current Architecture Overview

### Current vs. Future System State Matrix

| Dimension | Current Baseline State | Production Implemented State (Platform v3.0.0) |
| :--- | :--- | :--- |
| **Public Edge & Ingress** | Paid GCP Compute `e2-micro` in `us-east1` (South Carolina, USA) with Static IP running WireGuard (`10.100.0.1`) and Nginx reverse proxy. | Cloudflare Zero Trust Tunnels (`cloudflared` in K3s) connecting to India Edge PoPs (Mumbai/Delhi/Chennai). |
| **Latency & Routing** | Multi-hop cross-Atlantic round trip (~450ms–500ms RTT; 15s–30s SPA load). | Edge terminated in India (<15ms RTT; <300ms full page render). |
| **Cloud Infrastructure Cost** | ~$7.00–$12.00/month in GCP VM compute, static IP reservation, and cross-region egress. | **Cost-Optimized (Zero Cloud Compute Egress Costs)** via OCI Mumbai & Cloudflare Zero Trust. Legacy GCP gateway detached. |
| **Out-of-Band Monitoring** | Internal-only Kube-Prometheus-Stack. ISP drops result in silent blackouts. | OCI Mumbai Compute VM running Uptime Kuma probing Cloudflare endpoints and Tailscale gateway. |
| **Public Web Applications** | None hosted locally (`vijaysingh.cloud` hosted externally on Hostinger). | Homelab Docs (`docs.vijaysingh.cloud`) on K3s. |
| **Deployment Lifecycle** | Manual `kubectl apply` commands; push-based Ansible playbooks; configuration drift prevalent. | Pull-based Flux CD v2 GitOps controller continuously reconciling `kubernetes/` from GitHub `main`. |
| **Secrets Management** | Ansible Vault (`vault.yml`) with hydration script writing ephemeral `terraform.tfvars` to disk. | Mozilla SOPS + Age encryption for in-Git Kubernetes secrets; decrypted in-memory by Flux. |
| **Database Architecture** | Standalone single PostgreSQL 15 pod (`apps/n8n/postgres.yaml`) on a 5Gi local PVC; no automated failover. | CloudNativePG (CNPG) Operator managing declarative HA cluster with automated continuous WAL archiving to MinIO. |
| **Workload Security** | n8n pod runs `hostNetwork: true`, `runAsUser: 0` in initContainers, and mounts root SSH keys for hypervisor remediation. | Non-root containers, dropped Linux capabilities, isolated network policies, SSH keys purged from pods. |
| **Remote Access (Admin)** | Tailscale mesh on `ops-center` advertising LAN subnet; direct Nginx reverse proxy without SSO. | Hybrid Model: Cloudflare Access (Google SSO / OTP) for private web UIs; Tailscale strictly for SSH/Proxmox. |
| **Observability & ChatOps** | Prometheus/Grafana inside K3s; broken Discord webhook alerts; isolated n8n alerts. | Centralized Slack workspace with 5 dedicated channels (`#daily-briefing`, `#documents`, `#homelab-alerts`, etc.). |
| **Disaster Recovery Tier** | Proxmox vzdump + Velero to local MinIO + Restic to local HDD. Zero offsite copy. | Complete 3-2-1 DR: NVMe (Hot) -> HDD (Local Cold) -> OCI Mumbai Object Storage (Offsite 3-2-1 Tier). |

### Current Scale & Non-Functional Specifications
- **Current Scale:** 1 Operator/Engineer (Vijay Singh); 2 active applications (n8n custom v6, Python PDF automation); ~100 requests/day; peak throughput <5 req/sec; local data footprint ~45GB on NVMe, ~120GB on HDD; database size <2GB.
- **Projected 1-Year Scale:** 5–10 active users (family members on BookOrbit/Audiobookshelf, sister's clients on portfolio); 9 production containerized workloads + 2 websites; ~5,000 requests/day; peak throughput 25 req/sec; storage volume ~450GB on HDD; database size ~15GB.
- **Projected 3-Year Scale:** 25 active users; 15 containerized services; ~25,000 requests/day; storage volume ~800GB on HDD (reaching drive capacity); database size ~40GB.
- **Service Level Objectives (SLOs):**
- **Availability:** Public Websites: 99.9% (Cloudflare edge cached); Internal Applications: 99.5% (subject to residential ISP and single-node power).
- **Latency:** Edge Static Cache: <20ms; Dynamic API / n8n Webhooks: <150ms; Internal Application UIs: <300ms.
- **Recovery Time Objective (RTO):** Critical Database (PostgreSQL): <30 minutes; Full Application Plane: <2 hours; Bare-Metal Host Disaster: <6 hours.
- **Recovery Point Objective (RPO):** Transactional Database (PostgreSQL): <15 minutes (via continuous WAL archiving); Application Manifests & Configurations: 0 minutes (SSOT in Git); File Storage / Documents: <24 hours (nightly backup).

---

## 3. Architectural Decision Inventory

The following major architectural decisions have been identified across the legacy and modernized infrastructure:

1. **Bare-Metal Virtualization via Proxmox VE (Accepted - Historical):** Selection of Proxmox VE as Type-1 hypervisor on Mini PC to isolate management, production, and learning environments.
2. **Dual-Tier Physical Storage Allocation (Accepted - Historical):** Partitioning NVMe SSD for I/O-intensive OS and container roots, and SATA HDD for archives, backups, and media.
3. **Hybrid Cloud Ingress via GCP Compute Gateway & WireGuard (Accepted - Historical / Deprecated by ADR-006):** Deploying a public GCP VM in South Carolina with WireGuard VPN to overcome residential ISP CGNAT.
4. **Ansible Vault "Hydration" Pattern for Terraform Secrets (Accepted - Historical):** Decrypting secrets in memory via Ansible playbooks to generate ephemeral `terraform.tfvars` without committing plaintext secrets.
5. **Tailscale Overlay Mesh for Out-of-Band Administration (Accepted - Historical):** Implementing a Zero Trust WireGuard overlay on `ops-center` with subnet routing for secure remote SSH and Proxmox management.
6. **Cloudflare Zero Trust Tunnels for Edge Ingress (Accepted - Implemented in v3.0.0):** Replacing the paid cloud gateway VM and WireGuard tunnel with outbound `cloudflared` daemons to eliminate costs, cut latency, and hide home IP.
7. **Pull-Based GitOps Continuous Delivery via Flux CD v2 (Accepted - Implemented in v3.0.0):** Adopting Flux CD v2 with trunk-based directory overlays, health checks, dependency sequencing, and automated image updates.
8. **Mozilla SOPS + Age Encryption for In-Git Kubernetes Secrets (Accepted - Implemented in v3.0.0):** Standardizing on CNCF-compliant in-repo secret encryption, decrypted dynamically inside K3s by Flux CD.
9. **Hardened Decoupling of the n8n Automation Engine (Accepted - Implemented in v3.0.0):** Eliminating `hostNetwork: true`, stripping root privileges, revoking node SSH keys from pods, and implementing an event-driven webhook remediation pattern.
10. **CloudNativePG (CNPG) High-Availability Database Architecture (Accepted - Implemented in v3.0.0):** Replacing single-pod PostgreSQL with a declarative CNPG operator managing HA replication and continuous WAL archiving to MinIO.
11. **Multi-Cloud Hybrid Resilience via OCI Mumbai (Accepted - Implemented in v3.0.0):** Establishing an OCI Mumbai Ampere A1 instance for out-of-band Uptime Kuma monitoring and offsite encrypted Restic backup synchronization.
12. **Hybrid Identity & Access Architecture (Accepted - Implemented in v3.0.0):** Using Cloudflare Access with Google SSO / Email OTP for browser-based private web apps, and Tailscale for underlying node administration.
13. **Cold Storage Tiering for Sovereign Media & Documents (Accepted - Implemented in v3.0.0):** Enforcing strict volume isolation and dedicated PVC mount patterns on the 1TB HDD for Paperless-ngx, BookOrbit, and Audiobookshelf.
14. **Deferral of Canary Deployments for Single-Replica Workloads (Accepted - Implemented in v3.0.0):** Postponing complex Flagger canary configurations until workloads scale beyond single-pod instances.
15. **Decommissioning of ops-center Virtual Machine (Accepted - Modernization):** Eliminating the 2GB RAM KVM VM in favor of remote Terraform state in OCI Object Storage and direct laptop administration over Tailscale, reclaiming 2GB RAM, 2 vCPUs, 20GB NVMe, and 250GB HDD.
16. **Retirement of Academy Zone (Accepted - Modernization):** Decommissioning and purging all 5 lab VMs/LXCs post-certification to reclaim ~7.5GB defined RAM and dedicate 12GB RAM to k3s-prod.

---

## 4. Missing / Undocumented Decisions

Prior to this architectural review, several critical operational and technical decisions were implicit, inconsistent, or undocumented:

1. **Offsite Backup & True Disaster Recovery Strategy (CRITICAL):** The system documented a "3-Layer Defense" (Proxmox vzdump, Velero, Restic), but all three layers targeted the *same physical machine* (the 1TB SATA drive inside the Mini PC). A single hardware failure, fire, or theft would result in total, irrecoverable data loss.
2. **Kubernetes Workload Security Standard & Host Network Isolation (CRITICAL):** No documented standard governed container security contexts. Consequently, `n8n` was granted `hostNetwork: true`, executed containers as root, and mounted host private SSH keys to run sudo commands on the hypervisor.
3. **Database HA, Connection Management & Lifecycle (CRITICAL):** PostgreSQL was deployed as an unmanaged single pod with static PVC storage. No policies existed for automated failover, Point-in-Time Recovery (PITR), transaction connection pooling, or zero-downtime minor version upgrades.
4. **GitOps Engine Standardization (Contradiction):** Documentation contained a conflict between ArgoCD (promoted in `README.md` and Phase 3 roadmaps) and Flux CD v2 (formalized in `GitOps Platform Standards`).
5. **Public Domain & Subdomain Delegation Architecture:** The relationship between the root domain (`vijaysingh.cloud` hosted on Hostinger/Cloudflare) and homelab services was undocumented, leading to confusion over domain purchase costs and DNS routing.
6. **Multi-User Data Isolation & RBAC for Digital Media:** The system lacked clear architectural rules defining authentication and file-level permissions for shared multi-user services like BookOrbit.
7. **Cloud Cost Governance & FinOps Thresholds:** No formal limits or monitoring existed to catch runaway cloud egress or compute billing on GCP or OCI.

---

## 5. Architectural Risks and Smells

### Smell 1: The "God Pod" Automation Pattern (Critical Security Violation)
- **Observation:** In `apps/n8n/n8n.yaml` and `scripts-configmap.yaml`, n8n runs with `hostNetwork: true`, `NODE_FUNCTION_ALLOW_EXTERNAL: "child_process"`, root permissions in initContainers, and mounts `/home/node/.ssh/id_rsa` to execute SSH commands against Proxmox bare-metal nodes (`remediate.py`) with `StrictHostKeyChecking=no`.
- **Why It Matters:** Any Remote Code Execution (RCE) vulnerability in n8n or an unauthenticated webhook payload gives an attacker unrestricted root access to the entire home local area network and the hypervisor hosting all workloads.
- **Severity:** **P0 — Critical**
- **ADR Required:** Yes (ADR-009).
- **Recommended Action:** Immediately strip `hostNetwork: true`, purge SSH keys from the container, isolate n8n inside a strict Kubernetes NetworkPolicy, and execute infrastructure remediation via an out-of-band webhook router or restricted API token with rate limiting.

### Smell 2: Co-Located Backups (Pseudo-Resilience Anti-Pattern)
- **Observation:** Proxmox vzdump, Velero S3 snapshots, and Restic host archives all write to `/mnt/hdd` on the same physical Mini PC chassis.
- **Why It Matters:** Violates the foundational rule of the 3-2-1 backup standard (1 offsite copy). Physical hardware failure, disk controller death, or physical destruction destroys primary data and all backup copies simultaneously.
- **Severity:** **P0 — Critical**
- **ADR Required:** Yes (ADR-011).
- **Recommended Action:** Provision an encrypted offsite backup target in Oracle Cloud Infrastructure Object Storage in Mumbai, synchronized nightly via Restic over an encrypted channel.

### Smell 3: Cross-Continental High-Latency Ingress Routing
- **Observation:** Public ingress routes through an `e2-micro` VM in GCP `us-east1` (South Carolina, USA), tunnels back across the Atlantic via WireGuard to an on-prem server in India, and terminates at Traefik.
- **Why It Matters:** Adds ~450ms–500ms of unavoidable network flight time per HTTP request. Single-Page Applications (SPAs) loading 40+ assets suffer compound load times exceeding 20 seconds, while incurring recurring GCP compute and network egress charges.
- **Severity:** **P1 — Important**
- **ADR Required:** Yes (ADR-006).
- **Recommended Action:** Decommission GCP gateway and adopt Cloudflare Zero Trust Tunnels terminating at Indian edge PoPs (<15ms latency).

### Smell 4: Single Stateful PostgreSQL Pod Without Streaming WAL Archiving
- **Observation:** n8n and other core services rely on a single PostgreSQL StatefulSet (`apps/n8n/postgres.yaml`) on a 5Gi ReadWriteOnce volume without WAL replication.
- **Why It Matters:** Crash consistency is not guaranteed. A corrupt database page or ungraceful VM termination requires restoring from the last daily backup, losing up to 24 hours of execution history, webhook payloads, and application credentials.
- **Severity:** **P0 — Critical**
- **ADR Required:** Yes (ADR-010).
- **Recommended Action:** Deploy the CloudNativePG operator to manage automated cluster self-healing, replica failover, and continuous WAL archiving to MinIO for Point-in-Time Recovery (PITR).

### Smell 5: Premature Delivery Over-Engineering (Flagger Canary on Single Replicas)
- **Observation:** `GitOps Platform Standards` mandates Flagger canary deployments with 10% traffic stepping for homelab applications.
- **Why It Matters:** Canary deployments mathematically require multiple running pods and sophisticated ingress traffic splitters. On a resource-constrained single-node cluster (16GB RAM) running 1-replica workloads, Canary analysis adds immense CPU/RAM overhead, creates routing failures, and wastes engineering hours.
- **Severity:** **P2 — Useful**
- **ADR Required:** Yes (ADR-014).
- **Recommended Action:** Defer Flagger canary pipelines. Use standard Kubernetes rolling updates with native HTTP readiness probes and atomic Git reverts for single-node workloads.

---

## 6. ADR Priority Matrix

| Priority | ADR Identifier & Title | Architectural Impact & Rationale |
| :---: | :--- | :--- |
| **P0** | **ADR-006: Ingress Modernization via Cloudflare Zero Trust Tunnels** | Eliminates public port scanning, removes single cloud VM failure point, cuts latency by 95%, and achieves ₹0.00 cloud egress cost. |
| **P0** | **ADR-008: Declarative In-Git Secrets Management via Mozilla SOPS + Age** | Eliminates manual credential hydration on host; ensures secrets in Git are cryptographically secure and unreadable without in-cluster private key. |
| **P0** | **ADR-009: Workload Hardening & Remediation Decoupling for Automation Engines** | Eliminates critical security vulnerability where an internet-exposed n8n container possesses host networking and hypervisor root SSH credentials. |
| **P0** | **ADR-010: Database Modernization via CloudNativePG HA Operator** | Protects system against data corruption and achieves <15 min RPO via continuous WAL streaming and Point-in-Time Recovery. |
| **P0** | **ADR-011: Multi-Cloud Hybrid Resilience: OCI Mumbai Support Plane for Out-of-Band Monitoring & Disaster Recovery** | Establishes the missing offsite tier for true 3-2-1 disaster recovery and enables true out-of-band outage alerting. |
| **P0** | **ADR-015: Decommissioning of ops-center VM via OCI Remote State & Laptop Control** | Reclaims 2GB RAM, 2 vCPUs, 20GB NVMe, and 250GB HDD; decouples Terraform state to OCI S3 and eliminates SSH bastion hops. |
| **P0** | **ADR-016: Retirement and Complete Purge of Academy Zone Post-Certification** | Reclaims ~7.5GB defined RAM across 5 idle VMs/LXCs, dedicating 12GB RAM and 4 vCPUs to the single production VM (k3s-prod). |
| **P1** | **ADR-001: Bare-Metal Virtualization via Proxmox VE with Logical Zones** | Foundation of the physical compute architecture; enforces strict memory and CPU boundaries on constrained 16GB Mini PC hardware. |
| **P1** | **ADR-002: Dual-Tier Physical Storage Allocation (NVMe vs. SATA HDD)** | Prevents high-IOPS write starvation on solid-state boot disks while ensuring large media libraries do not exhaust cluster storage. |
| **P1** | **ADR-007: Pull-Based GitOps Continuous Delivery via Flux CD v2** | Eliminates configuration drift, enforces single source of truth in Git, and automates disaster recovery deployments. |
| **P1** | **ADR-012: Hybrid Zero-Trust Identity Architecture (Cloudflare Access + Tailscale)** | Prevents public attack surfaces on private administrative dashboards without incurring the massive RAM overhead of self-hosted Keycloak. |
| **P1** | **ADR-013: Sovereign Media & Document Storage Tiering Strategy** | Governs storage mounting, backup deduplication, and volume boundaries for data-heavy workloads (Paperless, BookOrbit, Audiobookshelf). |
| **P2** | **ADR-004: In-Memory "Vault Hydration" Pattern for Bare-Metal Secrets** | Documents historical bare-metal bootstrapping secrets pattern; prevents Terraform variables from leaking onto unencrypted disks. |
| **P2** | **ADR-005: Out-of-Band Administrative Access via Tailscale Mesh** | Documents remote access pattern for hypervisor and infrastructure maintenance over non-routable CGNAT connections. |
| **P2** | **ADR-014: Progressive Delivery Scoping: Deferral of Flagger Canaries** | Simplifies deployment pipelines, prevents premature optimization, and conserves cluster memory on single-node hardware. |

---

## 7. Comprehensive Architecture Decision Records

```
================================================================================
ADR-001: Bare-Metal Virtualization via Proxmox VE with Isolated Logical Zones
================================================================================
```
- **Status:** Accepted (Historical) — **Updated by ADR-015 & ADR-016 (Modernization)**
- **Date:** December 2025 (Updated September 2026)
- **Owner:** Principal Architect / Homelab Platform Team
- **Context:** The infrastructure runs on a single physical Mini PC powered by an Intel Core i5 processor and 16GB of DDR4 RAM. The platform must support production-grade workloads (K3s Kubernetes cluster, automation, databases), a dedicated management control plane (Ansible, MinIO, backup runners), and experimental learning environments ("Kubernetes The Hard Way" labs) without allowing experimental failures to destabilize production.
- **Problem Statement:** How do we partition a single, resource-constrained physical machine to run production services, infrastructure management tooling, and ephemeral lab clusters with strict resource isolation and predictable stability?
- **Decision Drivers:**
- Resource isolation between production workloads and experimental labs.
- Strict RAM capping to prevent Out-Of-Memory (OOM) kernel panics on the 16GB host.
- Granular snapshotting and disaster recovery at the hypervisor layer.
- Support for both lightweight Linux Containers (LXC) and full hardware-virtualized VMs (KVM).
- **Decision:** We will use **Proxmox Virtual Environment (PVE) 9.x** as the Type-1 hypervisor:
- *Historical Tri-Zone Architecture (Dec 2025):* Partitioned into Zone M (`ops-center` 2GB RAM), Zone P (`k3s-prod` 8GB RAM), and Zone A (Academy Lab ~7.5GB RAM defined).
- *Modernized Lean Consolidation (Sept 2026 - ADR-015 & ADR-016):* Zone A and Zone M have been completely decommissioned. Host compute is 100% consolidated into a **single dedicated production VM: `k3s-prod` (VMID 500)** allocated **12GB RAM and 4 vCPUs**, leaving ~3.5GB RAM for the Proxmox host OS, Linux kernel buffers, and `vzdump` snapshot compression.
- **Architecture Impact:** Affects all bare-metal compute resources. Terraform manages VM lifecycle via the `bpg/proxmox` provider. Host kernel memory is governed by Proxmox cgroups.
- **Alternatives Considered:**
- *Bare-Metal Ubuntu OS with Docker Compose:* High performance and lowest memory overhead. Rejected because it lacks hard resource isolation, does not allow snapshot-based hypervisor disaster recovery, and cannot support multi-node Kubernetes lab topologies.
- *VMware ESXi:* Industry enterprise standard. Rejected due to Broadcom licensing restrictions, poor consumer Mini PC NIC driver compatibility, and lack of native lightweight LXC container support.
- **Decision Rationale:** Proxmox provides open-source, enterprise-grade KVM/LXC management with native backup utilities (`vzdump`), full API programmability via Terraform, and zero licensing fees.
- **Consequences:**
- *Positive:* Hard failure domain isolation; ability to take bare-metal block snapshots; ephemeral lab nodes can be stopped to free 8GB of RAM for production.
- *Negative:* Virtualization incurs ~1.5GB RAM hypervisor overhead; managing Proxmox API provider quirks in Terraform (e.g. `pm_minimum_permission_check`).
- *Risks:* Single physical host failure crashes all zones simultaneously.
- *Trade-offs:* Sacrificing 10% raw bare-metal compute performance for virtualization agility and recovery boundaries.
- **Security Considerations:** Hypervisor management interface (Port 8006) is bound strictly to the LAN and Tailscale overlay; no exposure to WAN.
- **Reliability Considerations:** Host Watchdog timers enabled; Proxmox VMs configured with `onboot = true` for Zone M and Zone P to ensure automatic recovery after power outages.
- **Scalability Considerations:** Limited to 16GB RAM. If workloads expand beyond 14GB active allocation, hardware must be upgraded or secondary compute added.
- **Performance Considerations:** CPU virtualization flags (VT-x) enabled in BIOS. K3s VM disk uses VirtIO SCSI single with IO thread enabled for near-native NVMe performance.
- **Operational Considerations:** Proxmox host updates managed via Debian APT; hypervisor backups taken prior to major PVE kernel upgrades.
- **Cost Considerations:** Infrastructure: ₹0.00 (Owned Mini PC hardware). Licensing: ₹0.00 (Community No-Subscription Repository).
- **Migration Plan:** System is already deployed and operational in this state.
- **Validation / Fitness Functions:**
- Hypervisor memory utilization must not exceed 85% during full production load.
- Zone P (`k3s-prod`) reboot must complete and achieve ready status in <90 seconds.
- **Dependencies:** Intel VT-x hardware virtualization; Proxmox VE 9.x.
- **Open Questions:** None.
- **Related ADRs:** ADR-002, ADR-005.
- **Review Conditions:** Hardware upgrade to 32GB/64GB RAM or addition of a secondary physical Proxmox cluster node.

---

```
================================================================================
ADR-002: Dual-Tier Storage Topology (Hot NVMe vs. Cold SATA HDD)
================================================================================
```
- **Status:** Accepted (Historical)
- **Date:** December 2025
- **Owner:** Principal Architect / Homelab Storage Team
- **Context:** The Mini PC chassis contains two physically disparate storage drives: a high-performance 256GB NVMe M.2 SSD and a high-capacity 1TB SATA 2.5" mechanical HDD. Initially, unpartitioned backups were written to the root filesystem, filling the small SSD and crashing running VMs.
- **Problem Statement:** How do we architect storage allocation across mismatched storage hardware to maximize application I/O throughput while ensuring capacity-heavy media, document archives, and disaster recovery snapshots do not exhaust primary operating system disks?
- **Decision Drivers:**
- High random IOPS required by K3s SQLite/etcd and PostgreSQL transactional databases.
- High storage capacity required for media streaming, OCR PDF archives, and hypervisor backups.
- Prevention of SSD write-wear and disk-full lockouts on OS partitions.
- **Decision:** We will establish a strict **Two-Tier Storage Topology**:
 1. *Tier 1 (Hot NVMe - 256GB - `local-lvm`):* Dedicated exclusively to Proxmox OS boot partitions, VM/LXC virtual system disks, and active database volumes.
 2. *Tier 2 (Cold SATA HDD - 1TB - `/mnt/hdd`):* Formatted as `ext4`, mounted via `/etc/fstab` on the host, and provisioned as Proxmox directory storage `backup-hdd`. Dedicated to Proxmox `vzdump` archives, MinIO object buckets, Velero snapshots, BookOrbit digital library, Audiobookshelf media, and Paperless-ngx document originals.

- **Architecture Impact:** Affects Proxmox storage pools, Terraform VM disk provisioning, and Kubernetes Persistent Volume Claim (PVC) storage classes.
- **Alternatives Considered:**
- *ZFS Mirror across NVMe and HDD:* Rejected because ZFS mirrors are throttled to the speed of the slowest drive (SATA HDD) and capacity is capped at the smaller drive (256GB), wasting 750GB of storage.
- *Single 1TB HDD for everything:* Rejected because K3s etcd and PostgreSQL write latency on mechanical platters causes extreme disk contention, high I/O wait, and pod evictions.
- **Decision Rationale:** Physical separation guarantees that heavy I/O workloads (Postgres) operate at >1,500 MB/s read/write without being choked by bulk sequential backup writes running on the HDD.
- **Consequences:**
- *Positive:* High I/O performance for applications; 1TB capacity preserved for cold media and backups; zero risk of backup jobs filling root OS drive.
- *Negative:* Manual path mounting required; secondary disk provisioning in Terraform requires dynamic SCSI blocks.
- *Risks:* SATA HDD failure will corrupt cold data and local backups if not mirrored or replicated offsite.
- *Trade-offs:* Cold tier has no local hardware RAID redundancy (JBOD model).
- **Security Considerations:** Storage mounts are restricted by Linux file permissions; MinIO S3 access requires secret key authentication.
- **Reliability Considerations:** HDD SMART status monitored regularly via `smartmontools`; cron alerts if reallocated sector counts rise.
- **Scalability Considerations:** NVMe capacity is capped at 256GB (currently ~45GB used). HDD capacity is 1TB (sufficient for ~3 years at projected ingestion rates).
- **Performance Considerations:** PostgreSQL transactional commits achieve sub-millisecond sync times on NVMe.
- **Operational Considerations:** Dedicated Proxmox storage identifier `backup-hdd` configured so backup tasks fail gracefully rather than spilling onto local NVMe.
- **Cost Considerations:** Infrastructure: ₹0.00 (Existing drives).
- **Migration Plan:** Storage tiering was successfully executed and documented in `docs/01-architecture.md`.
- **Validation / Fitness Functions:**
- NVMe root partition free space must remain >25% at all times.
- Disk I/O wait (`wa` in top) during nightly backups must not degrade K8s API latency by >10%.
- **Dependencies:** Linux `fstab`, Proxmox storage subsystem.
- **Open Questions:** None.
- **Related ADRs:** ADR-001, ADR-011, ADR-013.
- **Review Conditions:** NVMe disk usage exceeds 80% or SATA HDD free space drops below 100GB.

---

```
================================================================================
ADR-003: Public Ingress via Cloud VM & WireGuard Site-to-Site Tunnel
================================================================================
```
- **Status:** Accepted (Historical) — **Superseded by ADR-006**
- **Date:** January 2026
- **Owner:** Principal Architect / Homelab Network Team
- **Context:** The on-premises homelab is connected to a residential Indian ISP operating behind Carrier-Grade NAT (CGNAT). The ISP does not provide a public IPv4 address, and incoming ports 80/443 are blocked upstream. Inbound webhooks (e.g. from GitHub to n8n) required a stable public entry point.
- **Problem Statement:** How do we establish a secure, static public ingress endpoint for incoming webhooks and traffic without exposing the home network or paying for expensive enterprise ISP static IP connections?
- **Decision:** We provisioned an **`e2-micro` Compute Engine instance on Google Cloud Platform (GCP)** with a static public IPv4 address in `us-east1` (South Carolina), configured Nginx reverse proxy with Certbot SSL termination, and established an encrypted **WireGuard site-to-site VPN tunnel (`10.100.0.0/24`)** connecting the GCP VM (`10.100.0.1`) to the on-prem K3s node (`10.100.0.3`).
- **Architecture Impact:** Traffic routed: Public Internet -> GCP Public IP -> GCP Nginx -> WireGuard Tunnel -> On-Prem Traefik Ingress -> n8n Pod.
- **Alternatives Considered:**
- *Port Forwarding on Home Router:* Rejected due to severe security violations (exposing home LAN directly) and technical impossibility under ISP CGNAT.
- *Dynamic DNS with GCP Spot Instances:* Tested and failed. Preemptible spot VMs caused "zombie states," IP churn, DNS propagation delays, and lost webhooks.
- **Decision Rationale:** Provided a stable static IP and eliminated home router port exposure, solving the CGNAT barrier during early platform phases.
- **Why It is Being Superseded:**
 1. The VM was provisioned in `us-east1` (USA) instead of India, forcing traffic from India to travel to North America and back, adding ~500ms latency.
 2. Running a dedicated GCP VM, static IPv4 reservation, and cross-region egress incurs **~$7–$12/month** in recurring charges, violating our zero-cost objective.
 3. WireGuard requires ongoing Linux kernel maintenance, handshake keepalives, and MTU tuning.

- **Related ADRs:** ADR-006.

---

```
================================================================================
ADR-004: In-Memory "Vault Hydration" Pattern for Bare-Metal Infrastructure Secrets
================================================================================
```
- **Status:** Accepted (Historical)
- **Date:** December 2025
- **Owner:** Principal Architect / DevOps Automation Team
- **Context:** Terraform requires plaintext variables (`terraform.tfvars`) to authenticate with the Proxmox API and cloud providers. However, committing plaintext `terraform.tfvars` to GitHub is a critical security violation. External secret managers like HashiCorp Vault or GCP Secret Manager introduce severe memory overhead or unwanted cloud dependencies.
- **Problem Statement:** How do we deliver credentials to Terraform during bare-metal host provisioning without storing unencrypted secrets in Git, without running a resource-heavy Vault server, and without manual copy-pasting?
- **Decision Drivers:**
- Zero plaintext secrets committed to version control.
- Support for air-gapped / offline bare-metal execution.
- Minimal resource footprint on the 16GB host.
- Unified tooling leveraging existing Ansible automation.
- **Decision:** We implemented the **"Vault Hydration Pattern"**:
 1. Non-sensitive configurations are stored in public Ansible vars (`group_vars/all.yml`).
 2. Sensitive credentials (API tokens, passwords) are encrypted via AES-256 using **Ansible Vault** (`group_vars/production/vault.yml`).
 3. A specialized playbook (`hydrate_infra.yml`) uses Jinja2 templates (`terraform.tfvars.j2`) to decrypt values in memory and generate ephemeral `terraform.tfvars` files locally on the deployment node just-in-time.
 4. Global `.gitignore` rules strictly prevent `terraform.tfvars` from ever being staged or committed.

- **Architecture Impact:** Governs bare-metal provisioning in `infrastructure/on-prem/` and legacy `infrastructure/gcp/`.
- **Alternatives Considered:**
- *Environment Variables (`export TF_VAR_...`):* Rejected due to poor developer experience and lack of auditability when managing 25+ infrastructure parameters.
- *HashiCorp Vault Cluster:* Rejected as severe over-engineering consuming >1GB RAM on the constrained host.
- **Decision Rationale:** Provides an elegant, zero-overhead bridge between Ansible encryption and Terraform input requirements while maintaining Git cleanliness.
- **Consequences:**
- *Positive:* Secrets are encrypted at rest in Git; zero additional server infrastructure required; deterministic variable generation.
- *Negative:* Ephemeral plaintext files exist temporarily on the host disk during Terraform runs; requires running an Ansible playbook before executing Terraform.
- *Risks:* Accidental modification of `.gitignore` could expose hydrated files if pre-commit hooks are absent.
- *Trade-offs:* Shifted secret decryption to the deployment machine rather than utilizing dynamic short-lived cloud tokens.
- **Security Considerations:** `.ansible_vault_pass` is excluded from Git; directory permissions on hydrated files restricted to `0600`.
- **Reliability Considerations:** Deterministic Jinja2 rendering guarantees identical variable outputs across runs.
- **Scalability Considerations:** Scales cleanly for any number of Terraform variables.
- **Performance Considerations:** Hydration playbook executes in <3 seconds.
- **Operational Considerations:** Requires operators to possess the Ansible Vault passphrase in their local environment.
- **Cost Considerations:** Infrastructure: ₹0.00.
- **Migration Plan:** Active and fully operational for bare-metal host bootstrapping. (Note: In-cluster Kubernetes secrets will transition to SOPS+Age per ADR-008).
- **Validation / Fitness Functions:**
- Git pre-commit hooks must scan and block any commit containing `terraform.tfvars`.
- **Dependencies:** Ansible, Ansible Vault, Jinja2.
- **Open Questions:** None.
- **Related ADRs:** ADR-008.
- **Review Conditions:** Migration to full ephemeral OpenTofu/Terraform Cloud agents.

---

```
================================================================================
ADR-005: Out-of-Band Administrative Access via Tailscale Mesh Overlay
================================================================================
```
- **Status:** Accepted (Historical) — **Updated by ADR-015 (Modernization)**
- **Date:** January 2026 (Updated September 2026)
- **Owner:** Principal Architect / Security & Operations Team
- **Context:** Remote administration of the Proxmox hypervisor, `ops-center`, and Kubernetes nodes requires network access when the operator is outside the home LAN (e.g. from coffee shops, mobile networks). Traditional router port-forwarding of SSH (Port 22) or Proxmox GUI (Port 8006) exposes the entire homelab to brute-force internet attacks and fails under ISP CGNAT.
- **Problem Statement:** How do we establish a zero-trust, location-agnostic remote administration channel for bare-metal infrastructure without exposing public ports and without managing complex dynamic DNS?
- **Decision Drivers:**
- Zero open ports on the physical ISP router.
- Strong end-to-end WireGuard cryptographic authentication with Multi-Factor Authentication (MFA).
- Ability to traverse CGNAT seamlessly.
- Low operational overhead.
- **Decision:** We deployed a **Tailscale Zero Trust Mesh Network** across the administrative tier:
 1. *Historical Setup (Jan 2026):* Tailscale daemon installed on `ops-center` as a subnet router.
 2. *Modernized Direct Model (Sept 2026 - ADR-015):* Under ADR-015, `ops-center` has been decommissioned. Tailscale is installed directly on the Proxmox VE hypervisor (`100.108.178.93`) and the operator's laptop. The laptop executes Ansible playbooks and SSH sessions directly to Proxmox and `k3s-prod` (`192.168.1.30`) with zero intermediate jump hosts or `ProxyCommand` hops.
 3. MagicDNS enabled with Cloudflare upstream DNS (`1.1.1.1`).

- **Architecture Impact:** Governs all out-of-band management traffic, SSH access, Proxmox web console, and inter-node administrative orchestration.
- **Alternatives Considered:**
- *Self-Hosted OpenVPN / WireGuard Server with Port Forwarding:* Impossible due to CGNAT without a cloud VPS bounce host, and incurs high maintenance overhead.
- *Cloudflare Tunnels for SSH / Proxmox Web GUI:* Feasible, but exposes hypervisor management endpoints to browser-based web access patterns and requires `cloudflared` client-side access binaries for terminal workflows.
- **Decision Rationale:** Tailscale operates transparently over UDP hole punching, utilizes state-of-the-art Noise/WireGuard protocols, enforces identity-based ACLs, and costs ₹0.00 on the free personal plan.
- **Consequences:**
- *Positive:* 100% remote connectivity from any network; zero firewall ports exposed; split-horizon DNS conflicts resolved.
- *Negative:* Dependency on Tailscale SaaS coordination plane (control plane); DERP relay fallback can add latency if direct UDP hole-punching fails.
- *Risks:* Compromise of operator's Tailscale identity grants access to the internal management subnet.
- *Trade-offs:* Reliance on a managed coordination server in exchange for zero-maintenance CGNAT traversal.
- **Security Considerations:** Tailscale admin account secured with Google SSO and hardware MFA; key expiry enforced every 90 days on client machines.
- **Reliability Considerations:** Even if Tailscale coordination is unreachable, established WireGuard tunnels continue passing peer-to-peer traffic.
- **Scalability Considerations:** Standard tier supports up to 100 devices and 3 users, far exceeding homelab requirements.
- **Performance Considerations:** Direct peer-to-peer connection provides full local bandwidth; DERP relays only utilized during restrictive firewall traversal.
- **Operational Considerations:** Documented in `docs/08-debugging-wan-connectivity.md` to prevent split-horizon SSH conflicts.
- **Cost Considerations:** Infrastructure: ₹0.00 (Tailscale Free Personal Plan).
- **Migration Plan:** Fully operational.
- **Validation / Fitness Functions:**
- Ping and SSH from external cellular network to `ops-center` must succeed with 100% packet delivery.
- **Dependencies:** Tailscale client, Linux IP forwarding on `ops-center`.
- **Open Questions:** None.
- **Related ADRs:** ADR-001, ADR-012.
- **Review Conditions:** Tailscale alters free-tier terms or self-hosted Headscale controller is required for complete control plane sovereignty.

---

```
================================================================================
ADR-006: Ingress Modernization: Migration from Cloud VM / WireGuard to Cloudflare Zero Trust Tunnels
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint) — **Supersedes ADR-003**
- **Date:** September 2026
- **Owner:** Principal Architect / Network Engineering
- **Context:** The legacy public ingress path (GCP `e2-micro` in `us-east1` running Nginx + WireGuard) incurs ~$7–$12/month in recurring costs, introduces ~500ms cross-Atlantic latency, creates MTU packet fragmentation, and requires managing a public Linux VM. Modern edge networking allows outbound-only encrypted tunnels that terminate directly at global Anycast CDN edge points.
- **Problem Statement:** How do we eliminate ongoing cloud VM billing, reduce public request latency from 500ms to <20ms, provide automatic DDoS protection, and simplify ingress networking without opening any ports on the residential router?
- **Decision Drivers:**
- FinOps: Absolute elimination of recurring cloud costs (Target: ₹0.00/month).
- Performance: Reducing round-trip latency for visitors in India from ~500ms to <15ms.
- Security: Zero inbound open ports; automatic edge DDoS mitigation and Web Application Firewall (WAF).
- Operational Simplicity: Removing cloud VM OS patching, WireGuard kernel configuration, and Certbot renewal cron jobs.
- **Decision:** We will **decommission the GCP Compute Gateway entirely** and deploy **Cloudflare Zero Trust Tunnels (`cloudflared`)** directly inside the `k3s-prod` cluster:
 1. Deploy `cloudflared` as a redundant Kubernetes deployment in namespace `cloudflare-system` (managed declaratively via Flux CD).
 2. Establish persistent, outbound-only QUIC/HTTPS tunnels to Cloudflare Anycast edge nodes in Mumbai, Delhi, and Chennai.
 3. Ingress routes will map public hostnames directly through `cloudflared` to the internal Traefik ingress service:

- Homelab Documentation: `docs.vijaysingh.cloud` -> Traefik -> `website-docs:80`
- Automation Webhooks: `hooks.vijaysingh.cloud` -> Traefik -> `n8n:5678`
 4. Universal SSL certificates and edge CDN caching will be terminated at Cloudflare's edge with HTTP/2 and HTTP/3 support.

- **Architecture Impact:** Completely removes `infrastructure/gcp/` and WireGuard peer configs. Introduces `kubernetes/platform/cloudflared/` and `infrastructure/cloudflare/` Terraform resources. Traefik shifts to an internal-only gateway receiving sanitized traffic from the local `cloudflared` daemon.
- **Alternatives Considered:**
- *Retain GCP VM and relocate to Mumbai (`asia-south1`):* Solves latency, but perpetuates ~$7/mo compute/IP billing and requires maintaining VM security patches and WireGuard configs.
- *Migrate WireGuard Gateway to OCI Compute VM in Mumbai:* Solves cost and latency, but still requires maintaining a cloud VM, Nginx proxy, Let's Encrypt certificates, and manual WireGuard keepalive watchdogs.
- *Direct Cloudflare Tunnels (Selected):* Zero cost, zero open ports, <15ms latency, built-in DDoS shield, native Edge CDN caching, and outbound-only traffic.
- **Decision Rationale:** Cloudflare Tunnels provide superior network edge performance, enterprise-grade DDoS resilience, zero operational VM maintenance, and 100% cost elimination.
- **Consequences:**
- *Positive:* Latency drops from ~500ms to <15ms; cloud bill reduced by 100% ($0/mo); zero open ports on firewall; automated edge SSL/TLS; automatic static asset CDN caching for documentation sites.
- *Negative:* Architectural dependency on Cloudflare's proprietary edge network and Terms of Service.
- *Risks:* Cloudflare service disruption could isolate public endpoints (mitigated by out-of-band Tailscale administrative access).
- *Trade-offs:* Relying on Cloudflare edge proxying rather than maintaining full end-to-end self-hosted network encapsulation.
- **Security Considerations:** Cloudflare manages TLS termination at edge; communication between Cloudflare and `cloudflared` pod is authenticated via tunnel secret token and encrypted over TLS 1.3/QUIC.
- **Reliability Considerations:** `cloudflared` runs with 2 replicas across the K3s node with automated reconnect logic.
- **Scalability Considerations:** Cloudflare Anycast edge automatically absorbs burst traffic, DDoS floods, and web scrapers without impacting homelab compute or residential bandwidth.
- **Performance Considerations:** Static website assets (Astro Docs, Nginx Portfolio) cached at edge PoPs, achieving sub-50ms Time to First Byte (TTFB) and 100/100 Google Lighthouse scores.
- **Operational Considerations:** Tunnel configuration managed declaratively as code in `infrastructure/cloudflare/` using the Cloudflare Terraform provider.
- **Cost Considerations:** Infrastructure Cost: **₹0.00 / month**. Savings: ~$84.00–$144.00 annually.
- **Migration Plan:**
 1. *Phase 1:* Deploy `cloudflared` in K3s and establish tunnel connection.
 2. *Phase 2:* Configure CNAME records in Cloudflare DNS for `docs`, and `hooks` pointing to the tunnel ID.
 3. *Phase 3:* Validate sub-300ms n8n canvas loading and webhook reception.
 4. *Phase 4:* Run `terraform destroy` on `infrastructure/gcp/` and release static IP to stop billing.

- **Validation / Fitness Functions:**
- Monthly GCP billing must drop to exactly $0.00.
- **Dependencies:** Cloudflare DNS zone `vijaysingh.cloud`, `cloudflared` container image.
- **Open Questions:** None.
- **Related ADRs:** ADR-003, ADR-011, ADR-012.
- **Review Conditions:** Cloudflare introduces tunnel egress bandwidth caps or alters service policies.

---

```
================================================================================
ADR-007: Pull-Based GitOps Continuous Delivery via Flux CD v2 with Trunk-Based Directory Overlays
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Platform Engineering
- **Context:** Currently, application deployments and Kubernetes manifest updates are applied imperatively via manual `kubectl apply` commands or Ansible playbooks pushed from the operator's laptop. This has resulted in configuration drift between the Git repository and cluster state, untracked modifications, and risk of cluster state divergence.
- **Problem Statement:** How do we establish an enterprise-grade, self-healing continuous delivery pipeline that guarantees the Git repository is the single source of truth (SSOT), prevents configuration drift, and supports automated rollbacks without manual intervention?
- **Decision Drivers:**
- Adherence to CNCF GitOps principles and Linux Foundation LFS269 standards.
- Eradication of configuration drift and manual `kubectl` interventions.
- Low in-cluster memory overhead (K3s runs on an 8GB VM).
- Native integration with Mozilla SOPS for secret decryption.
- Clean separation of platform infrastructure vs. application workloads.
- **Decision:** We will standardize on **Flux CD v2** implementing a **Trunk-Based Development model with Directory Overlays**:
 1. *Branching Strategy:* Single `main` branch protected by automated GitHub Actions CI checks (Kubeconform, Trivy, Yamllint). No long-lived environment branches (`dev`/`stage`/`prod`).
 2. *Repository Structure:*

- `kubernetes/bootstrap/`: Flux root sync definitions.
- `kubernetes/platform/`: Cluster-wide controllers (CloudNativePG, Traefik, Monitoring, `cloudflared`).
- `kubernetes/apps/`: Individual application Kustomize overlays (`n8n`, `bookorbit`, etc.).
 3. *Reconciliation Engine:* Flux controllers (`source-controller`, `kustomize-controller`, `helm-controller`) reconcile live state from Git.
 4. *Reliability Rules:* Mandatory explicit `healthChecks`, strict dependency sequencing via `dependsOn` (e.g. databases ready before apps), and automated garbage collection (`prune: true`).

- **Architecture Impact:** Deprecates imperative deployment scripts. Manifests in `apps/` migrate to declarative Kustomize packages in `kubernetes/`.
- **Alternatives Considered:**
- *ArgoCD:* Extremely popular with a rich web UI. Rejected because ArgoCD's multi-pod architecture consumes ~600MB–1GB RAM, creating unnecessary memory pressure on the 8GB K3s node, and its UI exposes an additional attack surface.
- *Ansible-Push Execution:* Current model. Rejected because push models cannot self-heal drift, lack native Kubernetes dependency reconciliation, and fail if the deployment node is offline.
- *Flux CD v2 (Selected):* Lightweight (~150MB total RAM), headless, declarative, CNCF Graduated, natively integrates with SOPS+Age, and aligns directly with LFS269 GitOps standards.
- **Decision Rationale:** Flux CD v2 delivers full enterprise GitOps capability with a tiny memory footprint perfectly suited for edge and homelab Kubernetes nodes.
- **Consequences:**
- *Positive:* Zero configuration drift; live state automatically self-heals within minutes; disaster recovery is an instantaneous `flux bootstrap` command; auditable Git commit log.
- *Negative:* Developers cannot run ad-hoc `kubectl apply` patches (changes will be immediately reverted by Flux); requires strict Kustomize discipline.
- *Risks:* A malformed manifest merged to `main` could fail reconciliations (mitigated by automated CI pre-merge validation).
- *Trade-offs:* Giving up ArgoCD's visual web dashboard in favor of saving ~700MB of critical cluster memory.
- **Security Considerations:** Flux operates inside the cluster using native RBAC service accounts; pulls code over SSH or authenticated HTTPS; secrets decrypted in-memory.
- **Reliability Considerations:** Dependency trees ensure the CloudNativePG operator and PostgreSQL clusters are 100% healthy before client pods (n8n, Paperless) are scheduled.
- **Scalability Considerations:** Architecture scales effortlessly to dozens of applications and multi-cluster setups without modifying repository layout.
- **Performance Considerations:** In-cluster controllers poll Git every 10 minutes, or instantly (<1 second) via push-based GitHub webhook receivers.
- **Operational Considerations:** Status notifications piped directly to Slack `#deployments` and GitHub commit status checks.
- **Cost Considerations:** Infrastructure: ₹0.00 (Open Source).
- **Migration Plan:**
 1. Run `flux bootstrap` targeting `kubernetes/bootstrap`.
 2. Commit platform definitions (`traefik`, `cnpg`) and verify reconciliation.
 3. Migrate application manifests from `apps/` to `kubernetes/apps/` sequentially.

- **Validation / Fitness Functions:**
- Manual changes applied via `kubectl` to a managed deployment must be automatically drifted-back and overwritten by Flux within 10 minutes.
- PR CI gate must block any invalid Kubernetes YAML before merge.
- **Dependencies:** K3s Kubernetes v1.28+, GitHub CLI / Flux CLI.
- **Open Questions:** None.
- **Related ADRs:** ADR-008, ADR-009, ADR-010, ADR-014.
- **Review Conditions:** Workload footprint expands to a multi-node cluster requiring visual multi-tenant UI (re-evaluating ArgoCD).

---

```
================================================================================
ADR-008: Declarative In-Git Secrets Management via Mozilla SOPS and Age Encryption
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / DevSecOps Team
- **Context:** Adopting GitOps (ADR-007) requires all Kubernetes manifests to reside in Git. However, storing plaintext `Secret` resources in Git is a critical security vulnerability. The existing Ansible Vault hydration pattern works well for bare-metal Terraform runs, but is incompatible with automated pull-based GitOps controllers like Flux CD.
- **Problem Statement:** How do we safely store, version-control, and manage sensitive application credentials (database passwords, API tokens, webhook secrets) directly inside the Git repository while ensuring they can be automatically and securely decrypted by Kubernetes?
- **Decision Drivers:**
- GitOps compliance: Secrets must be version-controlled alongside application code.
- Cryptographic security: Plaintext must never exist in the Git commit history.
- Human readability: Ability to view diffs and review PRs without decrypting non-sensitive metadata.
- Lightweight, cloud-agnostic decryption inside K3s.
- **Decision:** We will standardize on **Mozilla SOPS** paired with **Age** asymmetric encryption for all Kubernetes secrets:
 1. *Key Management:* A single Master Age keypair is generated. The public key is stored in `.sops.yaml` in the repository root. The private key is stored exclusively as a Kubernetes Secret (`sops-age`) in the `flux-system` namespace and on the operator's secure workstation.
 2. *Encryption Scope:* All secret manifests follow the naming standard `*.sops.yaml`. SOPS encrypts only the sensitive payload values (`data` and `stringData`), leaving object metadata (`metadata.name`, `namespace`, labels) in cleartext for Git review.
 3. *In-Cluster Decryption:* Flux CD's `kustomize-controller` is configured with `decryption.provider: sops`, decrypting secrets in-memory during reconciliation without writing plaintext to disk.

- **Architecture Impact:** Replaces manual `kubectl create secret` commands. Eliminates Ansible Vault dependencies for Kubernetes workloads.
- **Alternatives Considered:**
- *Bitnami Sealed Secrets:* Mature Kubernetes-native tool. Rejected because sealed secrets produce opaque binary blobs that obscure field-level git diffs, cannot be decrypted locally outside the cluster, and create complex recovery loops if the master controller pod dies.
- *External Secrets Operator (ESO) + Cloud Secrets Manager:* Rejected because pulling secrets from GCP or AWS adds recurring cloud API costs, network latency, and violates our sovereign cloud objective.
- *Mozilla SOPS + Age (Selected):* CNCF standard, transparent git diffs, offline local editing capability (`sops edit`), ultra-lightweight, and natively integrated into Flux CD.
- **Decision Rationale:** SOPS + Age offers the highest developer ergonomics, auditable git diffs, zero operational server footprint, and sovereign offline recovery.
- **Consequences:**
- *Positive:* Secrets safely committed to Git; PR reviews show clear field modifications; instant automated decryption in K3s; disaster recovery restores secrets automatically from Git.
- *Negative:* Developers must install `sops` and `age` CLIs locally; losing the private Age key renders all committed secrets permanently unrecoverable.
- *Risks:* Committing an unencrypted secret by accidentally omitting the `.sops.yaml` extension.
- *Trade-offs:* Managing a master Age private key backup vs. running dynamic secret management servers.
- **Security Considerations:** Automated CI pre-commit checks and GitHub Actions gates (`gitleaks`, `trivy`) scan all PRs to verify that unencrypted secrets are rejected before merge.
- **Reliability Considerations:** Master Age private key is backed up securely in the operator's offline password vault (1Password / Bitwarden).
- **Scalability Considerations:** Supports multi-key encryption (e.g. encrypting for multiple cluster keys simultaneously).
- **Performance Considerations:** In-memory decryption consumes <5ms during Flux reconciliation.
- **Operational Considerations:** Editing existing secrets is as simple as running `sops kubernetes/apps/n8n/secret.sops.yaml`.
- **Cost Considerations:** Infrastructure: ₹0.00 (Open Source).
- **Migration Plan:**
 1. Generate Age keypair; load private key into K3s `flux-system/sops-age`.
 2. Convert existing `apps/n8n/secrets.example.yaml` into real encrypted `secret.sops.yaml`.
 3. Configure Flux Kustomization decryption block and test reconciliation.

- **Validation / Fitness Functions:**
- CI pipeline must fail immediately if any manifest with `kind: Secret` lacks the `sops:` metadata block.
- **Dependencies:** `sops`, `age`, Flux CD v2.
- **Open Questions:** None.
- **Related ADRs:** ADR-004, ADR-007, ADR-009.
- **Review Conditions:** Requirement for dynamic short-lived credentials or enterprise secret rotation policies.

---

```
================================================================================
ADR-009: Workload Hardening & Remediation Decoupling for Automation Engines
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Information Security Team
- **Context:** The current n8n deployment (`apps/n8n/n8n.yaml`) was historically configured with `hostNetwork: true`, root privileges in initContainers (`runAsUser: 0`), and `NODE_FUNCTION_ALLOW_EXTERNAL: "child_process"`. Furthermore, ConfigMap `n8n-scripts` mounts a private SSH key into the container so a Python script (`remediate.py`) can execute commands against the bare-metal Proxmox hypervisor (`192.168.1.3`) with `StrictHostKeyChecking=no`.
- **Problem Statement:** The automation engine is directly reachable from the public internet (receiving webhooks) while simultaneously holding hypervisor root SSH credentials and host network privileges. A single remote code vulnerability in n8n would provide an attacker full, unhindered root compromise of the entire physical server and private home network.
- **Decision Drivers:**
- Principle of Least Privilege and Zero Trust workload isolation.
- Elimination of critical attack paths from public webhooks to bare-metal hypervisors.
- Compliance with Pod Security Standards (Restricted / Baseline).
- Preserving required self-healing automation without compromising host integrity.
- **Decision:** We will **completely decouple infrastructure remediation from the application workload and enforce strict workload hardening**:
 1. *Network Isolation:* Remove `hostNetwork: true` immediately. n8n will run inside standard Kubernetes pod SDN networking with explicit default-deny `NetworkPolicy` rules allowing ingress only from Traefik and egress only to PostgreSQL and DNS.
 2. *Security Context Hardening:* Enforce non-root execution (`runAsUser: 1000`, `runAsGroup: 1000`, `allowPrivilegeEscalation: false`). Purge the root `initContainer` by properly configuring Kubernetes `fsGroup: 1000` on the volume mount.
 3. *Credential Purge:* Permanently remove `/home/node/.ssh/id_rsa` and `remediate.py` from the n8n container and ConfigMaps.
 4. *Out-of-Band Remediation:* If automated hypervisor remediation (e.g. restarting a service) is required, n8n will dispatch a signed, authenticated webhook event to an isolated daemon on `ops-center` or use the Proxmox REST API with a heavily scoped, fine-grained API token (never raw root SSH).

- **Architecture Impact:** Modifies `kubernetes/apps/n8n/` deployment manifests. Eliminates security vulnerability on Proxmox host.
- **Alternatives Considered:**
- *Retain SSH script but restrict with `sudoers`:* Rejected because mounting private SSH keys inside an internet-facing web application container remains an unacceptable attack surface.
- *Complete elimination of self-healing automation:* Unnecessary; self-healing can be achieved safely via scoped REST APIs.
- **Decision Rationale:** Securing the boundary between containerized applications and bare-metal hypervisors is non-negotiable in a production-grade sovereign cloud.
- **Consequences:**
- *Positive:* Eliminates the single largest security risk in the homelab; prevents container escape to host network; achieves CIS Kubernetes benchmark compliance.
- *Negative:* Self-healing scripts cannot execute arbitrary bash commands on the host; requires proper API token management.
- *Risks:* Legitimate automation workflows requiring shell execution must be refactored.
- *Trade-offs:* Slightly more complex API integration in exchange for complete host security isolation.
- **Security Considerations:** Enforces Kubernetes Restricted Pod Security Standards; drops `ALL` Linux capabilities.
- **Reliability Considerations:** Container crashes or restarts cannot destabilize the physical node's network stack.
- **Scalability Considerations:** Hardened pod can be scaled or migrated to any worker node without host-specific networking bindings.
- **Performance Considerations:** Standard overlay networking eliminates host port collisions.
- **Operational Considerations:** Logs and health probes standard across all cluster workloads.
- **Cost Considerations:** Infrastructure: ₹0.00.
- **Migration Plan:**
 1. Update `apps/n8n/n8n.yaml` to remove `hostNetwork` and SSH mounts.
 2. Apply updated `network-policy.yaml`.
 3. Verify n8n successfully connects to PostgreSQL and receives external webhooks via Cloudflare Tunnel.

- **Validation / Fitness Functions:**
- Pod must successfully start and run with `hostNetwork: false` and `runAsNonRoot: true`.
- Trivy container scans must report zero critical privilege escalation vulnerabilities.
- **Dependencies:** Kubernetes CNI (K3s Flannel), Traefik Ingress.
- **Open Questions:** None.
- **Related ADRs:** ADR-006, ADR-007, ADR-010.
- **Review Conditions:** Introduction of new automation tasks requiring node-level metrics.

---

```
================================================================================
ADR-010: Database Modernization: Migration from Standalone PostgreSQL Pod to CloudNativePG HA Operator
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Data Platform Engineering
- **Context:** The current database tier consists of a standalone, single-pod PostgreSQL 15 container deployed via a basic StatefulSet (`apps/n8n/postgres.yaml`) mounted to a 5Gi local volume. It lacks automated failover, Point-in-Time Recovery (PITR), automated backups, connection pooling, and declarative maintenance capabilities.
- **Problem Statement:** How do we transform our database tier into an enterprise-grade, highly reliable data platform that guarantees data integrity, automates continuous backup streaming, and supports zero-downtime upgrades while fitting within our 16GB host memory budget?
- **Decision Drivers:**
- Prevention of data corruption and data loss during ungraceful power interruptions.
- Point-in-Time Recovery (PITR) with an RPO < 15 minutes.
- Automated database lifecycle management (rolling minor upgrades, declarative user/schema management).
- Strict resource budgeting to prevent RAM starvation on the K3s host.
- **Decision:** We will deploy the **CloudNativePG (CNPG) Operator** to manage our transactional database tier:
 1. *Operator Deployment:* Managed declaratively via Flux CD HelmRelease in `kubernetes/platform/postgres-operator/`.
 2. *Cluster Topology:* Deploy a declarative PostgreSQL cluster (initially 1 primary with automated replication readiness, expanding to 2 instances if memory permits) using high-performance NVMe storage for active tables.
 3. *Continuous WAL Archiving:* CNPG configured to continuously stream Write-Ahead Logs (WAL) and base backups to our local MinIO S3 bucket on the 1TB SATA HDD.
 4. *Multi-Tenant Database Provisioning:* n8n, Paperless-ngx, and future apps will consume distinct, isolated logical databases and credentials managed declaratively via CNPG CRDs rather than spawning separate PostgreSQL container instances.

- **Architecture Impact:** Replaces `apps/n8n/postgres.yaml`. Affects all stateful application database configurations across the cluster.
- **Alternatives Considered:**
- *Retain Standalone StatefulSet with Cron pg_dump:* High risk of data loss between daily dumps (24-hour RPO); manual recovery; no health monitoring.
- *Zalando Postgres Operator:* Mature, but heavy resource footprint and complex CRD architecture compared to CNPG.
- *CloudNativePG (Selected):* CNCF ecosystem favorite, purpose-built for Kubernetes, minimal memory footprint (<50MB operator RAM), native Barman-based WAL streaming, and exceptional documentation.
- **Decision Rationale:** CNPG provides enterprise-grade database automation, continuous WAL streaming for near-zero RPO, and native S3 backup integration with minimal resource overhead.
- **Consequences:**
- *Positive:* Automated continuous WAL backup; instantaneous point-in-time recovery; consolidated database instances save ~400MB RAM across the cluster; zero-downtime minor version rolling upgrades.
- *Negative:* Learning curve for managing declarative CNPG CRDs (`Cluster`, `Backup`, `ScheduledBackup`).
- *Risks:* Misconfigured MinIO S3 credentials could stall WAL archiving (mitigated by CNPG Prometheus metrics and alert rules).
- *Trade-offs:* Consolidating multiple application databases onto a unified managed CNPG cluster rather than completely isolated standalone DB containers.
- **Security Considerations:** TLS encryption enforced for all client connections; database passwords managed via SOPS-encrypted secrets.
- **Reliability Considerations:** Continuous WAL streaming ensures that even if the NVMe drive crashes mid-day, the database can be restored to within minutes of the failure.
- **Scalability Considerations:** Supports read-only replica scaling and connection pooling via PgBouncer integration if web traffic spikes.
- **Performance Considerations:** Transaction commit logs written to high-speed NVMe SSD; sequential WAL archives streamed asynchronously to HDD MinIO without blocking database writes.
- **Operational Considerations:** Monitored via native CNPG Prometheus metrics scraped by Kube-Prometheus-Stack.
- **Cost Considerations:** Infrastructure: ₹0.00 (Open Source).
- **Migration Plan:**
 1. Deploy CNPG Operator via Flux CD.
 2. Create CNPG `Cluster` manifest configured with MinIO S3 backup target.
 3. Execute `pg_dump` of existing n8n standalone database.
 4. Restore dump into new CNPG cluster database.
 5. Update n8n environment variables to point to `postgres-cluster-rw` service.
 6. Decommission legacy `apps/n8n/postgres.yaml`.

- **Validation / Fitness Functions:**
- Automated test restore from MinIO WAL backup must complete in <15 minutes.
- RPO must be validated at <15 minutes.
- **Dependencies:** Flux CD v2, MinIO S3 bucket on `ops-center`.
- **Open Questions:** None.
- **Related ADRs:** ADR-002, ADR-007, ADR-008, ADR-011.
- **Review Conditions:** Application read load requires dedicated read-replicas or horizontal database sharding.

---

```
================================================================================
ADR-011: Multi-Cloud Hybrid Resilience: OCI Mumbai Support Plane for Out-of-Band Monitoring (Uptime Kuma) and Offsite Disaster Recovery
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Cloud Operations & FinOps
- **Context:** The homelab currently lacks true out-of-band monitoring; if the home ISP drops or the power fails, internal Prometheus instances crash silently and cannot dispatch alerts. Furthermore, all existing backups (vzdump, Velero, Restic) reside on the single physical 1TB HDD inside the Mini PC, violating the 3-2-1 backup rule.
- **Problem Statement:** How do we establish a resilient out-of-band external monitoring sensor and a secure offsite disaster recovery repository without incurring monthly cloud infrastructure costs?
- **Decision Drivers:**
- True external observability: Detecting home ISP and power failures instantly.
- True 3-2-1 disaster recovery: Retaining an encrypted offsite copy of critical data.
- Strict FinOps constraint: ₹0.00 / month cost target (eliminating GCP's $7–$12/mo bill).
- Geographical proximity: Cloud resources located in India (Mumbai) for minimum latency.
- **Decision:** We will provision an **Oracle Cloud Infrastructure (OCI) support instance in the Mumbai region (`ap-mumbai-1`)**:
 1. *Compute Instance:* Provision an OCI Compute VM managed via Terraform (`infrastructure/oci/`).
 2. *FinOps Safeguard:* Enforce a strict ₹1.00 budget threshold and email alarm in OCI to guarantee zero unexpected billing.
 3. *Out-of-Band Monitoring (Uptime Kuma):* Deploy Uptime Kuma on the OCI VM to probe public endpoints (`docs.vijaysingh.cloud`, `hooks.vijaysingh.cloud`) and home router connectivity via Tailscale, sending instant alerts to Slack `#homelab-alerts`.
 4. *Offsite 3-2-1 Backup Target:* Configure an encrypted Restic repository backed by OCI Object Storage in Mumbai, synchronizing database dumps, configurations, and document assets nightly via AES-256 encryption.
 5. *Terraform S3 Remote State Backend:* Host the remote Terraform state bucket in OCI Object Storage in Mumbai, enabling resilient offsite state locking and decoupling state survival from local hardware availability (per ADR-015).

- **Architecture Impact:** Replaces `infrastructure/gcp/` with `infrastructure/oci/`. Establishes external monitoring, remote state backend, and true geographic disaster recovery.
- **Alternatives Considered:**
- *AWS Promotional Tier:* Rejected because AWS EC2 promotion expires after 12 months, leading to unexpected billing traps.
- *Retaining GCP e2-micro:* Rejected because GCP charges ~$4/mo for static IPs and cross-region egress, whereas OCI provides permanently free compute, static IPs, and 10TB free monthly egress.
- **Decision Rationale:** OCI provides high-durability regional compute and object storage directly in Mumbai (`ap-mumbai-1`), fulfilling out-of-band requirements with zero egress surcharges.
- **Consequences:**
- *Positive:* True 3-2-1 disaster recovery achieved; instant notifications during home power/internet outages; ₹0.00 recurring cloud spend; GCP completely decommissioned.
- *Negative:* OCI has strict idle resource reclamation policies for unused compute instances.
- *Risks:* OCI account suspension or region capacity limits for Ampere A1 shapes.
- *Trade-offs:* Running monitoring on ARM64 cloud architecture while local homelab runs x86_64.
- **Security Considerations:** Restic repository encrypted locally with AES-256 before transmission; OCI VM accessible strictly via SSH keys and Tailscale.
- **Reliability Considerations:** Uptime Kuma operates outside the home power/ISP failure domain, ensuring 100% reliable blackout alerting.
- **Scalability Considerations:** OCI 200GB free storage provides ample headroom for encrypted database dumps and critical document archives for multiple years.
- **Performance Considerations:** Low latency (<20ms) between OCI Mumbai and residential connection in India.
- **Operational Considerations:** Managed via standard Terraform in `infrastructure/oci/`; monitored via OCI budget alerts.
- **Cost Considerations:** Infrastructure: **₹0.00 / month**.
- **Migration Plan:**
 1. Provision OCI Mumbai VCN and VM via Terraform.
 2. Configure ₹1 budget alarm.
 3. Deploy Uptime Kuma and link Slack webhook for `#homelab-alerts`.
 4. Configure nightly encrypted Restic push from `k3s-prod` and Proxmox to OCI.
 5. Migrate Terraform state from local MinIO to OCI Object Storage bucket.

- **Validation / Fitness Functions:**
- Simulating home internet disconnection must trigger an Uptime Kuma Slack alert in `#homelab-alerts` within 120 seconds.
- Offsite Restic snapshot verification (`restic check`) must succeed nightly.
- **Dependencies:** OCI account, Terraform OCI provider.
- **Open Questions:** None.
- **Related ADRs:** ADR-002, ADR-006, ADR-010.
- **Review Conditions:** OCI policy or regional capacity changes occur.

---

```
================================================================================
ADR-012: Hybrid Zero-Trust Identity Architecture: Cloudflare Access (SSO/MFA) for Web Applications and Tailscale for Host Infrastructure
================================================================================
```
- **Status:** Proposed (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Security Architecture
- **Context:** The modernized homelab will host multiple private administrative and personal applications (Homepage Dashboard, BookOrbit, Paperless-ngx OCR, Miniflux). Exposing these services to the public internet creates significant attack surfaces for brute-force attacks and zero-day authentication exploits. However, deploying a self-hosted enterprise identity provider like Keycloak consumes ~800MB–1.2GB RAM and requires complex database clustering.
- **Problem Statement:** How do we enforce strong Single Sign-On (SSO), Multi-Factor Authentication (MFA), and zero-trust access control across all private web applications and infrastructure nodes without consuming the limited RAM of our 16GB Mini PC?
- **Decision Drivers:**
- Elimination of public login attack surfaces for private services.
- Enforcement of Multi-Factor Authentication (MFA) across all administrative access.
- Extreme memory efficiency: Preserving cluster RAM for actual applications.
- Seamless user experience for family members (e.g. Google SSO or Email OTP).
- **Decision:** We will implement a **Hybrid Zero-Trust Identity Architecture**:
 1. *Private Web Application Layer (Browser Access):* Governed by **Cloudflare Zero Trust Access**:

- Private subdomains (`dash.vijaysingh.cloud`, `books.vijaysingh.cloud`, `docs-ocr.vijaysingh.cloud`) are protected at Cloudflare's edge before traffic touches the homelab.
- Authentication enforced via **Google OAuth / SSO** or **One-Time Pin (OTP)** sent to approved email addresses.
- Unauthenticated requests are blocked at the edge; zero unauthorized packets reach the home network.
 2. *Infrastructure & Node Administration Layer (Terminal Access):* Governed by **Tailscale**:

- Raw Proxmox GUI (Port 8006), SSH (Port 22), and Kubernetes API (Port 6443) are accessible strictly over the private Tailscale WireGuard mesh (`100.x.x.x`).
- **Architecture Impact:** Deprecates planned Keycloak deployment. Governs all ingress route configurations in `kubernetes/apps/` and Cloudflare Access rules in `infrastructure/cloudflare/`.
- **Alternatives Considered:**
- *Self-Hosted Keycloak (OIDC/SAML):* Enterprise standard. Rejected due to massive RAM footprint (consuming 10–15% of total cluster memory), complex maintenance, and high risk of operator lockout.
- *Authelia / Authentik:* Lighter than Keycloak (~250MB RAM), but requires maintaining internal Redis, forward-auth proxy middleware in Traefik, and internal certificate authorities.
- *Hybrid Cloudflare Access + Tailscale (Selected):* Consumes **0 MB RAM** on the homelab, enforces Google MFA at the edge, blocks attacks before they reach the server, and provides frictionless user access.
- **Decision Rationale:** Cloudflare Access shifts authentication processing and brute-force mitigation entirely to the cloud edge at zero memory cost, while Tailscale provides ironclad encryption for terminal administration.
- **Consequences:**
- *Positive:* Zero RAM consumed on the Mini PC; private apps completely invisible to the public internet; enforced MFA; frictionless access for sister and family via Google sign-in.
- *Negative:* Third-party dependency on Cloudflare Access tier (up to 50 users included).
- *Risks:* Cloudflare edge outage blocks access to private web UIs (mitigated by bypassing via Tailscale direct LAN connection).
- *Trade-offs:* Cloud-brokered identity in exchange for saving 1GB+ RAM on physical hardware.
- **Security Considerations:** Enforces Google MFA and email whitelist policies; session duration configured to 24 hours for daily apps.
- **Reliability Considerations:** Administrator retains break-glass direct access via Tailscale and physical console.
- **Scalability Considerations:** Cloudflare Access covers 50 users, far exceeding the projected 3-year requirement of 25 users.
- **Performance Considerations:** Edge authentication takes <50ms; authenticated sessions cached via secure cookies.
- **Operational Considerations:** Policies managed declaratively via Terraform in `infrastructure/cloudflare/`.
- **Cost Considerations:** Infrastructure: Cost-Optimized (Cloudflare Zero Trust).
- **Migration Plan:**
 1. Configure Cloudflare Access application policies for `dash`, `books`, and `docs-ocr`.
 2. Map identity providers (Google SSO).
 3. Validate access from unauthenticated browsers.

- **Validation / Fitness Functions:**
- Unauthenticated requests to `dash.vijaysingh.cloud` must be stopped at edge with an HTTP 302 redirect to Cloudflare Access login.
- **Dependencies:** Cloudflare Access, Google OAuth Client ID.
- **Open Questions:** None.
- **Related ADRs:** ADR-005, ADR-006.
- **Review Conditions:** Requirement for air-gapped identity or team expansion beyond 50 users.

---

```
================================================================================
ADR-013: Sovereign Document & Media Storage Tiering Strategy on 1TB HDD
================================================================================
```
- **Status:** Recommended (Future Decision)
- **Date:** September 2026
- **Owner:** Principal Architect / Application Platform
- **Context:** The modernization blueprint introduces storage-heavy applications: Paperless-ngx (OCR searchable document archive), BookOrbit (multi-user digital book and PDF library), and Audiobookshelf (audiobook streaming). These workloads generate hundreds of gigabytes of unstructured binary files that would quickly overwhelm the 256GB NVMe SSD.
- **Problem Statement:** How do we structure persistent volume allocation, directory paths, and backup exclusions on the 1TB HDD to ensure multi-user media workloads operate reliably without degrading transactional database performance?
- **Decision Drivers:**
- Preventing storage exhaustion on the 256GB NVMe drive.
- Managing large multi-user media assets cleanly across application lifecycles.
- Isolating media files from high-frequency database backup schedules to conserve backup bandwidth.
- **Decision:** We will establish a standardized **Cold Storage Mount & PVC Pattern**:
 1. *Host-Level Storage Organization:* Dedicated, isolated directory hierarchies on `/mnt/hdd/`:

- `/mnt/hdd/data/paperless/`: Document archive, originals, and OCR exports.
- `/mnt/hdd/data/books/`: BookOrbit library assets and multi-user reading caches.
- `/mnt/hdd/data/media/`: Audiobookshelf audio files and podcast downloads.
- `/mnt/hdd/backups/`: Proxmox vzdump snapshots and local MinIO S3 buckets.
 2. *Kubernetes Storage Provisioning:* Provision individual PersistentVolumes using a dedicated `local-storage-hdd` storage class, mapped via Kustomize in each application overlay.
 3. *Backup Tiering:* Unstructured media files (e.g. EPUBs/Audiobooks) will be backed up via deduplicated weekly Restic snapshots, while transactional databases (PostgreSQL metadata) remain on continuous WAL archiving.

- **Architecture Impact:** Affects Kubernetes manifests for Paperless-ngx, BookOrbit, and Audiobookshelf.
- **Alternatives Considered:**
- *NFS Network Share from separate NAS:* Rejected because adding an external NAS incurs hardware and power costs.
- *Dynamic Provisioner writing to NVMe root:* Rejected; media ingestion would exhaust the SSD within weeks.
- **Decision Rationale:** Direct host directory mounting to the 1TB HDD provides predictable capacity planning, native ext4 file performance, and simplified backup scripting.
- **Consequences:**
- *Positive:* 1TB capacity utilized efficiently; SSD protected from media bloat; clear operational file structure.
- *Negative:* Workloads bound to the specific node path (`local-storage`).
- *Risks:* Concurrent heavy I/O (e.g. bulk OCR processing while streaming audiobooks) can cause mechanical disk head thrashing.
- *Trade-offs:* Read speeds capped at SATA HDD limits (~140 MB/s), which is completely sufficient for books, documents, and media streaming.
- **Security Considerations:** Linux permissions enforced (`UID 1000:1000`); Paperless documents encrypted at rest by Restic during offsite backup.
- **Reliability Considerations:** File integrity verified via ext4 filesystem journaling; weekly SMART disk checks.
- **Scalability Considerations:** Supports up to 800GB of media before requiring a secondary physical drive upgrade.
- **Performance Considerations:** Paperless-ngx OCR processing scheduled at low CPU nice priority to prevent starving transactional databases.
- **Operational Considerations:** Clean directory layouts enable rapid manual recovery if Kubernetes manifests must be rebuilt.
- **Cost Considerations:** Infrastructure: ₹0.00.
- **Migration Plan:** Standardize directory creation via Ansible bare-metal bootstrap playbook prior to deploying application Kustomizations.
- **Validation / Fitness Functions:**
- No media or document files may reside on the `local-lvm` NVMe storage pool.
- **Dependencies:** Proxmox storage mount, ext4 filesystem on 1TB HDD.
- **Open Questions:** None.
- **Related ADRs:** ADR-002, ADR-011.
- **Review Conditions:** HDD utilization reaches 85% capacity.

---

```
================================================================================
ADR-014: Progressive Delivery Scoping: Deferral of Canary Deployments for Single-Replica Workloads
================================================================================
```
- **Status:** Recommended (Future Decision)
- **Date:** September 2026
- **Owner:** Principal Architect / DevOps Platform Team
- **Context:** Section 10 of `GitOps Platform Standards` details the implementation of **Flagger** for automated Canary / Blue-Green releases with metric-driven rollback (analyzing request success rates and incrementally shifting traffic 10% -> 50% -> 100%).
- **Problem Statement:** In a single-node homelab running on 16GB RAM where applications (documentation, n8n) run as single-replica deployments, does implementing Flagger progressive delivery justify the significant architectural complexity and resource overhead?
- **Decision Drivers:**
- Principle of Parsimony: Avoiding premature optimization and unnecessary complexity.
- Resource conservation on 16GB Mini PC hardware.
- Technical feasibility: Canary traffic shifting requires multiple pod replicas and sophisticated ingress controllers.
- Developer productivity for a solo engineer.
- **Decision:** We will **formally defer Flagger progressive canary delivery** for the current and 1-year roadmap:
 1. *Application Deployments:* Standardize on native Kubernetes **Rolling Updates** (`maxSurge: 1`, `maxUnavailable: 0`) paired with strict HTTP liveness and readiness probes.
 2. *Static Websites:* documentation sites will rely on Cloudflare Edge CDN caching and instant atomic container replacement.
 3. *Rollback Mechanism:* Rollbacks will be executed via GitOps standard practice: `git revert <commit-sha>`, which Flux CD will reconcile within seconds.
 4. *Future Trigger:* Flagger will be evaluated only when an application scales to >=3 replicas and serves critical high-volume production traffic requiring automated traffic splitting.

- **Architecture Impact:** Simplifies `kubernetes/platform/` by omitting Flagger controllers and complex Prometheus canary analysis metrics, saving cluster memory and CPU cycles.
- **Alternatives Considered:**
- *Full Flagger Canary Implementation:* Recommended by LFS269. Rejected for current scale because running canary pods duplicates memory usage per app and adds unnecessary failure modes for static websites and low-traffic webhooks.
- **Decision Rationale:** A CTO must eliminate over-engineering. In a single-node homelab, Flagger adds negative business value and operational friction without providing meaningful reliability gains.
- **Consequences:**
- *Positive:* Saves ~300MB cluster RAM; simplifies deployment manifests; reduces pipeline debugging time; eliminates complex ingress routing loops.
- *Negative:* Traffic cannot be shifted incrementally (10% -> 20%); deployments are binary rolling updates.
- *Risks:* A bug passing readiness probes will serve traffic to 100% of users until `git revert` is pushed.
- *Trade-offs:* Foregoing automated percentage-based traffic stepping to maintain lean, maintainable infrastructure.
- **Security Considerations:** Not applicable.
- **Reliability Considerations:** Native Kubernetes readiness probes prevent traffic from routing to unhealthy replacement containers.
- **Scalability Considerations:** Architecture can easily incorporate Flagger in the future by adding the HelmRelease when multi-node scaling occurs.
- **Performance Considerations:** Zero latency overhead from traffic routing mesh.
- **Operational Considerations:** Simple deployment debugging via standard `kubectl rollout status`.
- **Cost Considerations:** Infrastructure: ₹0.00.
- **Migration Plan:** Omit Flagger manifests during Phase 4 platform deployment; utilize standard Kustomize Deployment manifests.
- **Validation / Fitness Functions:**
- Application deployments must achieve zero-downtime rolling updates verified by continuous curl health probes.
- **Dependencies:** Kubernetes native Deployment controller.
- **Open Questions:** None.
- **Related ADRs:** ADR-007.
- **Review Conditions:** Application scaled to >=3 replicas or sister's portfolio reaches >100,000 requests/day.

---

```
================================================================================
ADR-015: Decommissioning of ops-center VM in Favor of OCI S3 Remote State and Direct Laptop Operations
================================================================================
```
- **Status:** Accepted (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / DevOps & Infrastructure Team
- **Context:** Historically, a dedicated KVM Virtual Machine named `ops-center` (VMID 900) was provisioned with 2 vCPUs, 2048 MB (2 GB) RAM, 20 GB NVMe OS disk, and a 250 GB virtual data disk from the 1TB HDD. Its sole functional purposes were: (1) hosting a Dockerized MinIO container on port 9000 to serve as the S3 remote state backend for Terraform, (2) acting as an SSH Jump Host (`ProxyCommand`) for the operator's laptop via Tailscale to access internal `192.168.1.x` IPs, and (3) running a nightly Restic backup cron script of MinIO data. However, the engineer's laptop already connects directly to the home network and Proxmox hypervisor (`100.108.178.93`) over Tailscale, rendering the jump host redundant. Furthermore, running an entire virtualized Ubuntu OS and Docker daemon consumes ~2GB of physical host RAM simply to store ~50KB of Terraform state.
- **Problem Statement:** How do we eliminate the 2GB RAM and CPU overhead of the `ops-center` VM while preserving high-availability, state-locked remote Terraform state storage and seamless, secure remote administration?
- **Decision Drivers:**
- Maximizing hardware utilization on the 16GB Mini PC.
- Eliminating unnecessary virtualization layers and operating system maintenance.
- Achieving true offsite resilience for Terraform state (preventing loss of state if the physical Mini PC fails).
- Streamlining developer operations to direct laptop-to-node administration.
- **Decision:** We will **completely decommission and delete the `ops-center` Virtual Machine**:
 1. *Terraform State Migration:* Migrate the remote Terraform state backend from local MinIO to **Oracle Cloud Infrastructure (OCI) Object Storage in Mumbai (`ap-mumbai-1`)**. OCI provides 20 GB of S3-compatible, encrypted, versioned object storage with state locking with zero egress fees, completely decoupled from local hardware survival.
 2. *Direct Laptop Operations:* The operator's laptop (Fedora) will execute Ansible playbooks and Terraform commands directly. Tailscale provides direct authenticated WireGuard connectivity to Proxmox and `k3s-prod` without requiring an intermediate bastion or `ProxyCommand`.
 3. *In-Cluster Backup Target:* In-cluster Kubernetes backups (Velero snapshots and CloudNativePG continuous WAL archiving) will target an in-cluster S3 service or persistent volume mapped directly to the 1TB SATA HDD tier.

- **Architecture Impact:** Purges `module "ops_center"` from `infrastructure/on-prem/main.tf`; removes `ansible_ssh_common_args` from `configuration/inventory/group_vars/hypervisor/vars.yml`; cleans up `hosts.yml`.
- **Alternatives Considered:**
- *Convert ops-center to Proxmox LXC Container:* Consumes only 256MB–512MB RAM. Rejected because local state storage still suffers from co-located disaster risk (if Mini PC hardware dies, state is lost with it). OCI Object Storage provides true offsite durability at zero local RAM cost.
- *Keep ops-center as a 1GB VM:* Rejected as unjustified memory waste on a single-node host.
- **Decision Rationale:** Moving Terraform state to OCI Object Storage achieves true offsite disaster resilience, saves 2GB of physical host RAM, eliminates proxy latency, and significantly reduces operational complexity.
- **Consequences:**
- *Positive:* Reclaims 2GB RAM, 2 vCPUs, 20GB NVMe, and 250GB HDD virtual disk; zero bastion maintenance; offsite state survivability.
- *Negative:* Requires network access to OCI Object Storage endpoint when running `terraform apply`.
- *Risks:* OCI API outage temporarily blocks Terraform runs (does not impact running production workloads).
- *Trade-offs:* Relying on cloud object storage for state files in exchange for 2GB local memory reclamation.
- **Security Considerations:** OCI Object Storage access keys encrypted via Ansible Vault / local credential store; bucket configured with private access only and TLS 1.3 encryption in transit.
- **Reliability Considerations:** OCI Object Storage has 99.9% SLA with automated geographic multi-AZ replication.
- **Scalability Considerations:** OCI Object Storage capacity comfortably accommodates Terraform state versioning.
- **Performance Considerations:** Terraform state operations complete in <1.5s over regional Indian internet connection.
- **Operational Considerations:** Laptop configured with standard AWS CLI / S3 credentials targeting the OCI endpoint.
- **Cost Considerations:** Infrastructure: Cost-Optimized (OCI Object Storage).
- **Migration Plan:**
 1. Create OCI Object Storage bucket `homelab-terraform-state` in `ap-mumbai-1`.
 2. Run `terraform init -migrate-state` to copy state from local MinIO to OCI.
 3. Verify clean state via `terraform state list`.
 4. Destroy VM 900 (`ops-center`) in Proxmox.

- **Validation / Fitness Functions:**
- `terraform plan` executes cleanly from the laptop targeting the OCI S3 backend.
- `ansible -m ping all` succeeds directly from laptop to Proxmox and `k3s-prod`.
- **Dependencies:** OCI Tenancy in `ap-mumbai-1`, Tailscale client on laptop and Proxmox.
- **Open Questions:** None.
- **Related ADRs:** ADR-001, ADR-004, ADR-005, ADR-011.
- **Review Conditions:** None.

---

```
================================================================================
ADR-016: Complete Decommissioning and Code Purge of the Academy / Lab Zone Post-Certification
================================================================================
```
- **Status:** Accepted (Active Modernization Blueprint)
- **Date:** September 2026
- **Owner:** Principal Architect / Platform Engineering
- **Context:** During the preparatory phase for the Kubernetes certification exam (CKA / "Kubernetes The Hard Way"), a dedicated logical zone ("Zone A: Lab / Academy Plane") was established in Proxmox. This zone defined 5 virtual nodes: `gateway` (LXC 100, 512MB RAM), `jumpbox` (VM 200, 1024MB RAM), `server` (VM 210, 2048MB RAM), `node-0` (VM 220, 2048MB RAM), and `node-1` (VM 221, 2048MB RAM), representing ~7.5GB of defined RAM. A custom playbook (`configuration/playbooks/manage_lab.yml`) was used to power the lab on and off to avoid host OOM crashes when running alongside `k3s-prod`. The certification exam has now been successfully passed, rendering the entire Academy Zone obsolete.
- **Problem Statement:** How do we cleanly eliminate the unneeded Academy Zone to maximize available physical compute for the production cluster, prevent configuration drift, and reduce repository clutter?
- **Decision Drivers:**
- Maximizing hardware utilization: Dedicating all physical CPU and RAM to production workloads.
- Code cleanliness: Purging obsolete Terraform blocks, variables, and playbooks.
- Operational simplicity: Eliminating multi-zone startup ordering and lab power management scripts.
- **Decision:** We will **permanently decommission and delete the entire Academy Zone**:
 1. *Proxmox Cleanup:* Destroy running/stopped VMs 100, 200, 210, 220, and 221 from Proxmox VE, purging their disk images from `local-lvm`.
 2. *Terraform Purge:* Remove `module "gateway"` and `module "k8s_cluster"` from `infrastructure/on-prem/main.tf`, and purge all associated variables from `variables.tf` and `terraform.tfvars.example`.
 3. *Ansible Inventory Purge:* Delete the `lab` group from `configuration/inventory/hosts.yml`, remove lab variables from `configuration/inventory/group_vars/all/vars.yml`, and delete `configuration/playbooks/manage_lab.yml`.
 4. *Resource Consolidation:* Reallocate the reclaimed compute resources directly into `k3s-prod` (VM 500), expanding its memory allocation from 8GB to **12GB RAM** and 4 vCPUs.

- **Architecture Impact:** Completely removes Zone A from infrastructure declarations; consolidates the on-premises platform into a single-VM architecture (`k3s-prod`) on Proxmox VE.
- **Alternatives Considered:**
- *Keep lab VMs stopped on disk:* Consumes ~40GB of valuable NVMe storage and leaves unmaintained configuration in Git. Rejected because Git history preserves the code if ever needed in the future.
- *Retain lab Terraform code in an archive directory:* Unnecessary maintenance burden; code is easily retrieved via Git tag/commit history.
- **Decision Rationale:** Code and infrastructure that serve no active production or ongoing development purpose create technical debt. Purging the Academy Zone frees 7.5GB of defined RAM and simplifies the repository.
- **Consequences:**
- *Positive:* 7.5GB RAM defined reclaimed; 40GB NVMe storage reclaimed; repository lines of code reduced; single-VM simplicity.
- *Negative:* Running multi-node Kubernetes experiments requires re-provisioning.
- *Risks:* None.
- *Trade-offs:* Sacrificing immediate local multi-node sandbox capabilities to maximize production workload headroom.
- **Security Considerations:** Removes unused SSH keys and network interfaces associated with lab VMs.
- **Reliability Considerations:** Eliminates accidental simultaneous startup of lab VMs that previously threatened to cause host OOM kernel panics.
- **Scalability Considerations:** Frees sufficient RAM for all 9 production applications and documentation platform.
- **Performance Considerations:** Full memory headroom prevents swap thrashing on the Proxmox host.
- **Operational Considerations:** Eliminates the need to run `manage_lab.yml` tags before working on the cluster.
- **Cost Considerations:** Infrastructure: ₹0.00.
- **Migration Plan:**
 1. Verify certification completion and backup any personal lab notes.
 2. Run `terraform destroy` on Academy modules or delete VMs directly in Proxmox.
 3. Purge code blocks from `infrastructure/on-prem/` and `configuration/`.

- **Validation / Fitness Functions:**
- `terraform plan` in `infrastructure/on-prem/` reflects only the single `k3s_prod` module.
- Proxmox GUI shows only VM 500 (`k3s-prod`) running.
- **Dependencies:** Proxmox VE API.
- **Open Questions:** None.
- **Related ADRs:** ADR-001, ADR-015.
- **Review Conditions:** None.

---

---
*End of Architecture Decision Records — Homelab-Ops Sovereign Cloud.*
