# Homelab-Ops: The Evolution of a Sovereign Cloud

![Platform](https://img.shields.io/badge/Platform-Hybrid%20Cloud%20(Proxmox%20%2B%20GCP)-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Project%20Status-Active%20Development-success?style=for-the-badge)

> **"This is not just a server in a closet. It is an enterprise-standard R&D platform simulating real-world constraints—Data Sovereignty, CGNAT traversal, Zero-Trust Networking, and Automated Disaster Recovery."**

---

## 📖 The Engineering Journey (From Bare Metal to Hybrid Cloud)

This repository documents the complete lifecycle of building a production infrastructure from scratch. It is organized by **Engineering Phases**, showcasing how the architecture evolved to solve increasingly complex problems.

### Phase 1: The Bare Metal Foundation (v1.0.0)
**Goal:** Establish a virtualization platform and experiment with Kubernetes orchestration.
* **The Hardware:** Sourcing a Mini PC (Intel i5, 16GB RAM) and configuring storage tiering (NVMe for OS, HDD for Backups).
* **The Stack:** Installed **Proxmox VE** as the Type-1 Hypervisor.
* **The Logic:** Created "Logical Zones" to separate Management (Ansible Control Node) from Production (K3s Cluster) and Lab (Ephemeral K8s nodes).
* **The Limitation:** The cluster was isolated behind a home router with no public access (CGNAT).

![v1 Architecture](images/v.1.0.0/HomeLab-Ops%20V1.0.0.svg)

---
### Phase 2: The Hybrid Bridge (v2.0.0)
**Goal:** Break the CGNAT barrier and establish a public presence without exposing the home network.
* **The Solution:** Architected a **Site-to-Site WireGuard Mesh**.
* **Cloud Gateway:** Provisioned a Google Cloud Platform (GCP) instance in Mumbai to act as the public "Front Door."
* **Traffic Flow:** Public traffic hits GCP -> Encrypted Tunnel -> On-Prem Traefik Ingress.
* **Infrastructure as Code:** Migrated manual setups to **Terraform** (GCP) and **Ansible** (On-Prem).

#### **⚡ Featured Implementation: Hybrid Cloud Automation (n8n)**
*A real-world stress test of the hybrid architecture: securely hosting a webhook-driven automation platform.*

**The Mission:** Build a "Sovereign Cloud" alternative to Zapier. The system must run workloads On-Premises (to save costs) but accept traffic securely from the Public Internet (GitHub Webhooks).

**Architecture Evolution (The path to stability):**
1.  **Stage 1: The "Direct Connect" Attempt (Naive)**
    * *Design:* Port Forwarding on Home Router.
    * *Why Rejected:* **Security Risk.** Exposing the home network directly violated "Zero Trust" principles.
2.  **Stage 2: The "Split-Brain" Dynamic Cloud (Experimental)**
    * *Design:* GCP **Spot VM** as a Gateway + "Watchdog" scripts to auto-heal the tunnel when preempted.
    * *Failure Mode:* **"Zombie States."** When IP addresses changed, DNS propagation lag caused Webhook failures. It also created significant **Ansible Drift**, as the inventory file was constantly outdated.
3.  **Stage 3: The "Stable Mesh" (Production Grade)**
    * *Design:* Migrated to **GCP Standard VM + Static IP** in Mumbai (`asia-south1`).
    * *Result:* Eliminated the "Circuit Breaker" issue. If the home lab goes down, the Gateway now serves a clean 502 error instead of a connection timeout. Latency dropped to <30ms.

> **Technical Challenges & Solutions:** You can read the full deep-dive [here](docs/journal/project-hybrid-cloud-automation.md).

![v2 Architecture](images/v.2.0.0/P1.hybrid-network/architecture-topology.png)
![v2 Architecture](images/v.2.0.0/P1.hybrid-network/automation-pipeline.png)
> The K3s Cluster architecture incorporates several planned future upgrades.
![v2.1 K3s Cluster](images/k3s-prod/k3s-architecture.png)

---
### Phase 3: The Platform Era (Roadmap & Active Dev)
**Goal:** Shift from "Building Infrastructure" to "Platform Engineering"—focusing on Supply Chain Security, Event-Driven Architectures, and GreenOps using GCP services.  

#### 🚧 Upcoming Implementation Specs

| Feature | Architecture / Implementation Plan | GCP Services / Cloud Tech |
| :--- | :--- | :--- |
| **1. Serverless "Burst" Worker** | **Event-Driven Hybrid Pattern:**<br>Instead of running heavy OCR tasks locally, MinIO upload events will trigger a container in the cloud.<br>_Why? Offloads compute-heavy tasks to Google Cloud Free Tier._ | **Cloud Run**, **Eventarc**, **Pub/Sub** |
| **2. Supply Chain Security** | **Secure Registry Pipeline:**<br>Implementing image signing and vulnerability scanning before any container reaches the Production cluster. | **Artifact Registry** (Optional), Trivy, Cosign, Kyverno |
| **3. GreenOps Automation** | **"Eco-Mode" Lab Manager:**<br>An **n8n** workflow that interacts with the Proxmox API to automatically freeze/thaw the 16GB "Lab Zone" based on study schedules. | Proxmox API, n8n |
| **4. GitOps Transformation** | **Pull-Based State Management:**<br>Migrating from Ansible-push to **ArgoCD**. The cluster will sync itself with this repo, ensuring "Configuration Drift" is impossible. | ArgoCD, Kustomize |
| **5. Hybrid Identity (IAM)** | **Single Sign-On (SSO):**<br>Centralizing access for service, Traefik, and SSH under one identity provider with MFA enforcement. | Keycloak, OIDC |

---
#### 📉 Architecture Evolution Plan
> *Current Focus: Moving stateful workloads (Postgres) to High-Availability Operators.*

* **Now:** Static Postgres Pods (Hard to scale, manual failover).
* **Next:** **CloudNativePG Operator** with automatic failover, Point-in-Time Recovery (PITR) to S3, and replica pooling.
---

## Technical Deep Dive

### 1. Infrastructure as Code (IaC)
I strictly adhere to the **Dry (Don't Repeat Yourself)** principle using modular design.
* **Terraform:** Split into `infrastructure/gcp` (Cloud Edge) and `infrastructure/on-prem` (Proxmox Resources).
* **Ansible:** Uses a "Control Node" pattern. The `ops-center` node bootstraps the entire fleet using Roles for Hardening, Docker, K3s, and Monitoring.

### 2. The "Hydration" Pattern (Security)
To maintain **Zero Trust** and keep secrets out of Git, I developed a "Hydration" workflow:
1.  Secrets are encrypted AES-256 in Ansible Vault (`vault.yml`).
2.  A specialized playbook (`hydrate_infra.yml`) decrypts these values in memory.
3.  It generates ephemeral `terraform.tfvars` files strictly on the deployment machine.
4.  **Result:** Terraform plans run with full context, but no secrets ever touch the disk unencrypted.

### 3. Observability & FinOps
* **Monitoring:** Full Prometheus/Grafana stack monitoring Kubernetes metrics and Hardware thermals.
* **Cost Control:** The entire cloud footprint is engineered to stay under minimal costs (~$5-$10/month) using reserved instances and efficient resource sizing.

---
### <img src="images/google-cloud.svg" height="20" alt="Google Cloud Logo" style="vertical-align: text-bottom;"/> **Google Cloud Implementation Details** 

| Service | Usage in Homelab-Ops |
| :--- | :--- |
| **Compute Engine (GCE)** | Hosts the WireGuard Gateway acting as the public "Front Door" to the private lab. |
| **VPC & Static IP** | Reserved External IP ensures 100% reliability for incoming Webhooks (GitHub -> n8n). |
| **Cloud NAT** | Provides secure outbound internet access for private cloud subnets (without exposing them). |
| **Cloud Run** *(Planned)* | Serverless compute target for sporadic, high-intensity tasks (OCR/PDF Processing). |
| **Eventarc** *(Planned)* | Event bus routing storage events (MinIO) to Cloud Run functions. |