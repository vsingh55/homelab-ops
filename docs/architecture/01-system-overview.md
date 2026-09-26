# 01. System Architecture Overview

> **Target Standard:** Sovereign Hybrid Cloud Architecture 
> **Environment:** Bare-Metal Hypervisor (Mumbai) + Multi-Cloud Support (OCI & GCP) 
> **Status:** Production Reference 

---

## 1. Executive Summary

The `homelab-ops` platform is a production-grade, self-healing **Sovereign Cloud Platform** engineered to provide enterprise-standard digital services, workflow automation, document management, and private cloud infrastructure while operating under strict real-world constraints:

1. **Carrier-Grade NAT (CGNAT) Traversal:** Securely accepting external webhooks and public user traffic without exposing home router ports or leasing static public IPv4 addresses.
2. **Deterministic GitOps Continuous Delivery:** Managing platform operators and applications declaratively with **Flux CD v2** and **Mozilla SOPS**, eliminating manual configuration drift and keeping secrets encrypted in Git.
3. **Dual-Tier Hardware Economics:** Overcoming disk I/O bottlenecks on a single Mini PC by partitioning high-IOPS NVMe flash for database engines and durable SATA mechanical disks for multi-terabyte media and document archives.
4. **Hybrid Multi-Cloud Resilience:** Supplementing the on-premise sovereign cluster with cloud infrastructure across **Oracle Cloud Infrastructure (OCI)** and **Google Cloud Platform (GCP)** for out-of-band availability monitoring, remote state locking, and secondary cloud compute.

---

## 2. High-Level System Topology

![Global Network Topology](../images/v.3.0.0/global-network-topology.png)

---

## 3. Core Architectural Boundaries

The platform enforces strict logical and physical boundaries between components:

| Architectural Domain | Location / Host | Primary Responsibilities | Network Isolation |
| :--- | :--- | :--- | :--- |
| **Public Edge Layer** | Cloudflare Edge (Global Anycast) | SSL termination, DDoS protection, Web Application Firewall (WAF), Anycast DNS routing. | External Public Internet |
| **Out-of-Band Cloud Plane** | OCI Mumbai & GCP | External health probes (Uptime Kuma), S3 remote state locking, offsite encrypted backup replication. | Isolated Cloud VCNs / Public IP |
| **Management Mesh** | Tailscale Overlay (P2P WireGuard) | Out-of-band administrative access directly from engineer laptop to Proxmox and K3s. | 100.64.0.0/10 Carrier Mesh |
| **Bare-Metal Virtualization** | Proxmox VE 8 (Intel i5 Mini PC) | Hardware virtualization, storage pool management, VM lifecycle, and host-level snapshot backups. | 192.168.1.0/24 Local Management |
| **Application & Platform Plane** | `k3s-prod` VM (K3s Kubernetes) | Container orchestration, operator lifecycle (CloudNativePG), automated GitOps delivery (Flux CD v2). | Calico / Flannel Overlay CIDR |

---

## 4. Key Architectural Trade-Offs

- **Single-Node vs. Multi-Node:** A single physical node was selected to minimize power consumption (~15-25W idle), acoustic noise, and physical footprint. High availability is achieved at the application and database level via CloudNativePG and automated GitOps recovery rather than running multiple power-hungry physical servers.
- **Cloudflare Tunnels vs. Cloud VPN Relay:** Replaced an earlier cross-continental WireGuard cloud relay (which had ~500ms latency and ongoing NAT costs) with Cloudflare Anycast Tunnels, cutting latency by ~97% (<15ms) while eliminating inbound firewall exposure.
- **In-Git Secrets vs. External HashiCorp Vault:** External Vault clusters require significant RAM (~1-2GB) and unseal infrastructure. Adopting Mozilla SOPS with Age asymmetric encryption keeps secrets version-controlled in Git, decrypted exclusively in-memory by Flux CD v2.
