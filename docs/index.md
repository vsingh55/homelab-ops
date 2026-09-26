# Homelab-Ops: Sovereign Cloud Infrastructure & GitOps Platform

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Proxmox%20VE%208%20%7C%20K3s%20Kubernetes-orange?style=for-the-badge&logo=proxmox" alt="Platform" />
  <img src="https://img.shields.io/badge/GitOps-Flux%20CD%20v2-blue?style=for-the-badge&logo=flux" alt="GitOps" />
  <img src="https://img.shields.io/badge/Edge%20Ingress-Cloudflare%20Zero%20Trust-F38020?style=for-the-badge&logo=cloudflare" alt="Cloudflare" />
  <img src="https://img.shields.io/badge/Secrets-SOPS%20%2B%20Age-green?style=for-the-badge&logo=gnupg" alt="SOPS" />
  <img src="https://img.shields.io/badge/Database-CloudNativePG%20HA-336791?style=for-the-badge&logo=postgresql" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Cloud%20Support-OCI%20%26%20GCP%20Hybrid-C74634?style=for-the-badge&logo=oracle" alt="Cloud Support" />
  <img src="https://img.shields.io/badge/IaC-Terraform%20%2B%20Ansible-7B42BC?style=for-the-badge&logo=terraform" alt="Terraform" />
  <img src="https://img.shields.io/badge/FinOps-Cost--Optimized%20Footprint-success?style=for-the-badge" alt="FinOps" />
  <img src="https://img.shields.io/badge/Edge%20Latency-%3C15ms-brightgreen?style=for-the-badge" alt="Latency" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge" alt="License" />
</p>

---

## 🧭 Executive Overview: The Project at a Glance

**Homelab-Ops** is a production-grade, self-healing **Sovereign Cloud Platform** engineered on physical bare-metal hardware in Mumbai, India, integrated with supporting cloud infrastructure in **Oracle Cloud Infrastructure (OCI)** and **Google Cloud Platform (GCP)**.

This platform simulates enterprise-scale infrastructure engineering while operating under strict real-world constraints:

1. **Carrier-Grade NAT (CGNAT) Traversal:** Securely accepting external webhooks and public user traffic without exposing home router ports or relying on static IPv4 leasing.
2. **Deterministic GitOps Continuous Delivery:** Managing platform operators and applications declaratively with **Flux CD v2** and **Mozilla SOPS**, eliminating configuration drift and keeping secrets versioned safely in Git.
3. **Dual-Tier Hardware Economics:** Overcoming disk I/O bottlenecks on a single Mini PC by partitioning high-IOPS NVMe flash for database engines and durable SATA mechanical disks for multi-terabyte media and document archives.
4. **Hybrid Multi-Cloud Resilience:** Supplementing the on-premise sovereign cluster with cloud infrastructure across **Oracle Cloud Infrastructure (OCI)** and **Google Cloud Platform (GCP)** for out-of-band availability monitoring, remote state locking, and secondary cloud compute.

---

## 🏛️ Architecture & System Design

To provide complete architectural clarity without visual clutter, the platform is organized into three distinct structural diagrams:

### 1. Global Multi-Cloud & Network Ingress Topology
*How external traffic, edge security, multi-cloud support, and the secure administrative mesh are organized:*

```mermaid
flowchart TD
    subgraph Edge["1. Edge Ingress & Content Delivery"]
        direction LR
        Users["🌐 Public Traffic & Webhooks\n(GitHub, Devices, Users)"]
        CF["🛡️ Cloudflare Zero Trust Edge\n(Anycast Ingress • WAF & DDoS • <15ms Latency)"]
    end

    subgraph CloudSupport["2. Multi-Cloud Support Plane (OCI & GCP)"]
        direction LR
        OCI["☁️ Oracle Cloud (Mumbai)\n• Uptime Kuma Health Probes\n• Terraform S3 Remote State Backend\n• Offsite Encrypted Backup Vault"]
        GCP["☁️ Google Cloud Platform\n• Secondary Support Compute VM\n• Automated Image Delivery (GHCR)"]
    end

    subgraph OnPrem["3. Sovereign Bare-Metal Infrastructure (Mumbai)"]
        direction TB
        PVE["🖥️ Proxmox VE 8 Hypervisor (Bare Metal Mini PC)"]
        K3S["☸️ k3s-prod Kubernetes Cluster (VM 500)\n• Ingress Tunnel Connector (cloudflared)\n• Platform Operators & Stateful Workloads"]
    end

    subgraph Admin["4. Zero-Trust Administrative Mesh"]
        Workstation["💻 Engineer Workstation"]
        Tailscale["🔒 Tailscale Encrypted WireGuard Mesh\n(Direct Host & Cluster Access • Zero Bastions)"]
    end

    %% Network flows
    Users --> CF
    CF <== "Encrypted QUIC Tunnel (Outbound Only • Zero Open Ports)" ==> K3S
    
    %% Support & Probes
    OCI -. "Out-of-Band Endpoint Probing" .-> CF
    K3S -. "Encrypted State & Backup Sync" .-> OCI
    
    %% Administration
    Workstation ==> Tailscale
    Tailscale -. "Direct SSH / API" .-> PVE
    Tailscale -. "Direct kubectl (100.x.x.x)" .-> K3S

    PVE --> K3S
```

---

### 2. Sovereign Bare-Metal & Cluster Architecture
*How physical hardware, hypervisor resource fencing, and tiered storage are partitioned:*

```mermaid
flowchart TD
    subgraph BareMetal["Physical Bare-Metal Node: Intel Core i5 Mini PC (16GB RAM)"]
        direction TB
        
        subgraph Hypervisor["Proxmox VE 8 Type-1 Hypervisor"]
            HostReserved["🖥️ Host OS & Kernel\n(3.5GB RAM Reserved • ZFS/ext4 Caches • vzdump Backups)"]
            
            subgraph VM500["k3s-prod Dedicated Production Cluster (12GB RAM | 4 vCPUs)"]
                direction TB
                
                subgraph NS_Platform["Namespace: platform"]
                    direction LR
                    CNPG["🐘 CloudNativePG HA Operator\n(PostgreSQL Self-Healing)"]
                    Telemetry["📊 Prometheus & Grafana\n(Cluster Telemetry)"]
                    Watch["🔔 kwatch Daemon\n(Instant Crash Notifier)"]
                    Dashboard["🏠 Homepage Portal\n(Command Center)"]
                end

                subgraph NS_Apps["Namespace: apps"]
                    direction LR
                    n8n["⚡ n8n Automation Engine"]
                    Paperless["📄 Paperless-ngx (OCR)"]
                    BookOrbit["📚 BookOrbit Library"]
                    Audio["🎧 Audiobookshelf Server"]
                    RSS["📰 Miniflux (Go / PG)"]
                end

                subgraph NS_Ingress["Namespace: cloudflared"]
                    CF_Pod["🚪 cloudflared QUIC Tunnel Daemon"]
                end
            end
        end

        subgraph StorageLayer["Dual-Tier Storage Architecture"]
            direction LR
            NVMe["⚡ Tier 1: Fast NVMe SSD (256GB)\n• Proxmox OS & K3s Root Disk\n• CloudNativePG Active DB Tables (High IOPS)"]
            HDD["💾 Tier 2: Bulk SATA HDD (1TB)\n• Paperless Document Index Archives\n• Book & Media Streaming Storage\n• Local Virtual Machine Backup Snapshots"]
        end
    end

    CF_Pod --> NS_Platform
    CF_Pod --> NS_Apps
    VM500 --- NVMe
    VM500 --- HDD
```

---

### 3. Declarative GitOps & Secret Lifecycle Pipeline
*How code changes flow automatically from Git into production without configuration drift:*

```mermaid
flowchart LR
    subgraph VCS["Version Control System"]
        GitRepo["📦 GitHub Repository\n(vsingh55/homelab-ops)"]
    end

    subgraph ClusterGitOps["In-Cluster GitOps Engine (Flux CD v2)"]
        direction TB
        SourceCtrl["📡 Source Controller\n(Polls Git Every 10m)"]
        KustCtrl["⚙️ Kustomize Controller\n(Dependency Chaining)"]
        SOPS["🔐 SOPS + Age Decryption\n(In-Memory Secret Hydration)"]
    end

    subgraph DeploymentStages["Deterministic Deployment Order"]
        direction TB
        StagePlatform["1️⃣ Platform Foundation\n(cloudflared, CNPG, Storage)"]
        StageApps["2️⃣ Application Fleet\n(dependsOn: platform)"]
    end

    subgraph ClusterState["Active Production State"]
        LivePods["🚀 Healthy Running Workloads\n(Self-Healing • Zero Drift)"]
    end

    %% Pipeline flow
    GitRepo --> SourceCtrl
    SourceCtrl --> KustCtrl
    KustCtrl --> SOPS
    SOPS --> StagePlatform
    StagePlatform ==>|Health Verified| StageApps
    StageApps --> LivePods
    LivePods -. "Continuous Drift Correction" .-> KustCtrl
```

---

## 📖 The Engineering Story: From Bare Metal to Sovereign GitOps

### Act I: The Bare-Metal Foundation
Every robust platform begins with physical constraints. The on-premise foundation is an ultra-efficient Intel Core i5 Mini PC with 16GB DDR4 RAM, a 256GB NVMe SSD, and a 1TB SATA mechanical drive. 

To convert this single machine into an enterprise platform, **Proxmox VE 8** was chosen as the Type-1 hypervisor. By budgeting host resources strictly—reserving 3.5GB of RAM for the Debian kernel, memory caching, and backup snapshot compression—a dedicated virtual machine (`k3s-prod`) was allocated **12GB RAM and 4 vCPUs**, ensuring high memory headroom for Kubernetes workloads while safeguarding the physical host against out-of-memory (OOM) kernel panics.

### Act II: Conquering the Network (Zero Trust Ingress)
Residential internet connections rarely provide static public IP addresses and are almost universally bound behind **Carrier-Grade NAT (CGNAT)**, making traditional port-forwarding impossible or insecure.

* **The Evolution:** Early iterations explored cloud gateway relays. While functional, routing cross-continental traffic introduced latency hops and incurred ongoing NAT maintenance.
* **The Production Standard:** The platform upgraded to **Cloudflare Zero Trust Anycast Tunnels (`cloudflared`)**. Operating as an in-cluster deployment, `cloudflared` initiates outbound-only QUIC connections to Cloudflare's nearest edge data centers (Mumbai, Delhi, Chennai). Public webhooks and traffic terminate at the edge in **<15ms**, protected by Cloudflare WAF and DDoS mitigation, with **zero open inbound ports on the home firewall**.

### Act III: GitOps Continuous Delivery & In-Git Secrets
Operating infrastructure through manual `kubectl apply` commands or ad-hoc scripts leads to configuration drift and operational opacity.

The modern platform runs on pure **GitOps Continuous Delivery** powered by **Flux CD v2**:
* The cluster continuously synchronizes its desired state from this Git repository.
* Workload reconciliation is deterministically ordered: platform foundations (storage classes, operators, ingress daemons) must report healthy before application workloads are scheduled (`apps` depends on `platform`).
* Sensitive tokens and database passwords are encrypted declaratively using **Mozilla SOPS + Age**. Because secrets remain encrypted in Git, they can be safely reviewed in pull requests, while the in-cluster Flux decryptor hydrates them into memory without leaving plaintext traces on physical disks.

### Act IV: Storage Economics & Stateful High Availability
Single-node virtualization often stumbles when high-IOPS database queries compete with heavy background disk writes:
* **Storage Tiering:** Fast NVMe storage is dedicated strictly to the OS, K3s state, and PostgreSQL data files. Multi-terabyte document indexing (Paperless-ngx) and audio/book streaming libraries are routed directly to the high-capacity 1TB SATA mechanical disk.
* **Database Modernization:** Rather than deploying fragile, static database pods, relational data is managed by the **CloudNativePG Operator**. The operator provides automated PostgreSQL lifecycle management, health monitoring, self-healing failover, and Write-Ahead Log (WAL) archiving.

### Act V: Multi-Cloud Resilience (Oracle Cloud & Google Cloud Support)
A monitoring system running inside the cluster it is supposed to monitor cannot alert you when the cluster itself dies. Furthermore, local backups are vulnerable if the physical host suffers hardware failure.

To achieve enterprise-grade resilience, the architecture integrates **Oracle Cloud Infrastructure (OCI)** and **Google Cloud Platform (GCP)** support instances:
* **Out-of-Band Health Probes:** An independent cloud VM in OCI Mumbai runs **Uptime Kuma**, continuously polling public endpoints over the public internet and dispatching alerts to Slack/Discord if homelab broadband or power fails.
* **Remote State & Offsite Backup:** Terraform state is stored securely with remote locking in an OCI Object Storage S3-compatible backend, and nightly encrypted Restic backups are pushed offsite, fulfilling the **3-2-1 backup rule** (3 copies, 2 media types, 1 offsite).
* **Multi-Cloud Compute Support:** Supporting cloud virtual machines across OCI and GCP provide compute targets for auxiliary services and remote operations.

---

## ⚡ Core Architecture Pillars

| Architectural Pillar | Core Technologies | How It Solves the Problem |
| :--- | :--- | :--- |
| **Zero-Trust Edge & Ingress** | Cloudflare Zero Trust, `cloudflared`, Traefik | Traverses CGNAT with outbound-only QUIC tunnels; provides edge WAF and reduces latency to <15ms with zero open router ports. |
| **GitOps Continuous Delivery** | Flux CD v2, Kustomize, GitHub | Pull-based reconciliation loop eliminates configuration drift; deterministic ordering ensures zero failed boots. |
| **In-Git Secret Decryption** | Mozilla SOPS, Age Cryptography | Secrets versioned declaratively in Git with asymmetric encryption; decrypted exclusively in-memory by Flux. |
| **Dual-Tier Storage Strategy** | NVMe Flash (256GB), SATA Mechanical (1TB) | Isolates high-IOPS database operations from bulk document indexing and media streaming workloads. |
| **Stateful Resilience & HA** | CloudNativePG (PostgreSQL Operator) | Self-healing relational database clustering with automated failover and continuous WAL archiving. |
| **Multi-Cloud Support Plane** | OCI Mumbai, GCP Support VM, Uptime Kuma | Independent external heartbeat monitoring and remote state locking; operates even during power or ISP outages. |

---

## 📦 Application Fleet & Workload Catalog

All services are containerized, declared in Git, and routed through Cloudflare Zero Trust:

```
Platform & Security
├── cloudflared             # High-availability Anycast edge ingress tunnel
├── postgres-operator       # CloudNativePG enterprise PostgreSQL lifecycle operator
├── homepage                # Homelab Command Center (Live CPU/RAM & status portal)
├── monitoring              # Prometheus metrics scraping & Grafana telemetry
├── kwatch                  # Instant Discord/Slack notifier for crashed pods
└── docs                    # MkDocs Material engineering handbook (docs.vijaysingh.cloud)

Operations & Workflow Automation
├── n8n                     # Hardened event-driven workflow automation engine
└── pdf-generator           # Automated document compilation microservice

Sovereign Documents & Media (1TB HDD Tier)
├── paperless-ngx           # OCR document ingestion, tagging, and search archive
├── bookorbit               # Multi-user digital book library & sync manager
└── audiobookshelf          # Audiobook and podcast streaming server

Productivity & Personal Health
├── miniflux                # Ultra-fast, lightweight Go RSS reader
├── linkding                # Bookmarking service with tag search
└── ryot / wger             # Fitness analytics and workout tracking platform
```

---

## 🖥️ Physical Hardware & Resource Budgeting

```mermaid
pie title Mini PC 16GB RAM Allocation
    "k3s-prod Kubernetes Cluster" : 12
    "Proxmox VE Base OS & ZFS/Caches" : 3.5
    "Emergency Host Safety Buffer" : 0.5
```

* **Physical Node:** Intel Core i5 Mini PC (4 Cores / 8 Threads)
* **Total Host RAM:** 16,384 MB (16 GB DDR4)
* **Production Cluster Allocation (`k3s-prod` VM 500):**
  - **Memory:** 12,288 MB (12 GB RAM) — gives >60% memory headroom for peak OCR ingestion and database queries.
  - **Compute:** 4 vCPUs dedicated to Kubernetes scheduler.
  - **Storage:** 50GB NVMe root disk + 1TB SATA HDD attached virtual disk.
* **Proxmox VE Host OS Allocation:**
  - **Memory:** 3,500 MB (3.5 GB RAM) reserved for Debian kernel, KVM hypervisor daemons, and `vzdump` backup compression.
  - **Storage:** ~20GB NVMe root partition for hypervisor binaries and ISOs.

---

## 📚 Standard Engineering Documentation & Enterprise Handbook

Following CNCF and enterprise platform standards, all architecture specifications, flagship project case studies, and incident post-mortems are documented in the sections below:

### 1. Production System Architecture (Single Source of Truth)
* **[01. System Architecture Overview](architecture/01-system-overview.md)** — High-level multi-cloud hybrid topology, design goals, and component boundaries.
* **[02. Hardware & Virtualization](architecture/02-hardware-and-virtualization.md)** — Bare-metal Mini PC specifications and Proxmox VE 8 memory fencing.
* **[03. Kubernetes & K3s Cluster](architecture/03-kubernetes-k3s-cluster.md)** — Single-node production K3s cluster architecture and namespaces.
* **[04. Zero-Trust Networking](architecture/04-zero-trust-networking.md)** — Cloudflare Zero Trust Anycast Tunnels and Tailscale administrative mesh.
* **[05. Dual-Tier Storage Strategy](architecture/05-dual-tier-storage.md)** — Partitioning high-IOPS NVMe flash from bulk mechanical SATA storage.

### 2. Featured Projects & Case Studies (Resume Showcase)
* **[Case Study: Zero-Trust Hybrid Ingress Engine](projects/01-zero-trust-ingress.md)** — CGNAT traversal, Anycast edge routing, WAF, and <15ms latency.
* **[Case Study: Declarative GitOps & In-Git Secrets](projects/02-gitops-and-sops.md)** — Continuous delivery via Flux CD v2 and Mozilla SOPS + Age encryption.
* **[Case Study: Stateful PostgreSQL Operator on Bare-Metal](projects/03-cloudnativepg-ha.md)** — CloudNativePG high-availability operator, automated failover, and WAL archiving.
* **[Case Study: Multi-Cloud Resilience & Out-of-Band DR](projects/04-multicloud-observability-dr.md)** — OCI Mumbai & GCP support compute, Uptime Kuma external probes, and 3-2-1 backup replication.

### 3. Architecture Decision Records (ADRs)
* **[Comprehensive ADR Register](adr/README.md)** — 16 formal Architecture Decision Records documenting every pivotal architectural decision (ADR-001 through ADR-016), following the Michael Nygard standard.

### 4. Operations & Runbooks
* **[Backup & Disaster Recovery Runbook](runbooks/01-backup-and-disaster-recovery.md)** — Procedures for 3-2-1 backup verification and bare-metal disaster recovery.
* **[Day-2 Cluster Operations Runbook](runbooks/02-cluster-operations.md)** — SOPS secret rotation, manual GitOps reconciliation, and host maintenance.

### 5. Historical Archive & Incident Post-Mortems (v1.0 & v2.0 Milestones)
* **[Engineering Archive Overview](archive/README.md)** — Historical milestones, early technical challenges, and iterative migrations leading to v3.0.
* **[Bare-Metal Boot Failure Post-Mortem](archive/post-mortems/01-debugging-boot-failure.md)** & **[WAN Connectivity Post-Mortem](archive/post-mortems/02-debugging-wan-connectivity.md)**
* **[Ansible Automation Journey](archive/post-mortems/04-ansible-automation-journey.md)** & **[Terraform Modularization](archive/post-mortems/05-terraform-modularization.md)**
* **[Hybrid Cloud Automation Journal (n8n)](archive/post-mortems/07-hybrid-cloud-automation-n8n.md)** & **[Self-Healing Watchdog](archive/post-mortems/08-self-healing-watchdog.md)**

---

## 🛠️ Quick Operator Runbook

### Secret Encryption Workflow (SOPS + Age)
```bash
# Encrypt an updated Kubernetes Secret manifest before committing to Git
sops --encrypt --in-place kubernetes/apps/n8n/secret.enc.yaml

# Directly edit an encrypted secret file using your default editor
sops kubernetes/apps/n8n/secret.enc.yaml
```

### GitOps Synchronization
```bash
# Force immediate reconciliation of the platform layer
flux reconcile kustomization platform --with-source

# Force immediate reconciliation of the application layer
flux reconcile kustomization apps --with-source
```

### Out-of-Band Host Administration (Tailscale Mesh)
```bash
# Direct SSH access to the Proxmox VE hypervisor
ssh root@100.108.178.93

# Direct SSH access to the Production K3s node
ssh devops@192.168.1.30

# Inspect active Cloudflare tunnel connections
kubectl logs -n cloudflared -l app.kubernetes.io/name=cloudflared --tail=50
```

---

## 👤 Engineering Leadership & Contacts

**Vijay Singh** — DevOps & Platform Engineer  
* **GitHub:** [@vsingh55](https://github.com/vsingh55)  
* **Documentation Portal:** [https://docs.vijaysingh.cloud](https://docs.vijaysingh.cloud)  
* **Homelab Command Center:** [https://hub.vijaysingh.cloud](https://hub.vijaysingh.cloud)  
* **System Status & Uptime:** [https://status.vijaysingh.cloud](https://status.vijaysingh.cloud)  

---

<p align="center">
  <sub>Engineered with precision, operational discipline, and pride in sovereign platform engineering.</sub>
</p>
