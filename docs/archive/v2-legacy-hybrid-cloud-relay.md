# Milestone v2.0: The Hybrid Cloud Relay Bridge (Legacy)

> **Platform Standard:** Historical Architectural Baseline  
> **Status:** Deprecated (Superseded by Sovereign Cloud v3.0)  
> **Original Timeframe:** Milestone v2.0 Architecture  
> **Key Technologies:** GCP Compute Engine, WireGuard Site-to-Site, MinIO S3 Backend, Ansible Vault Hydration  

---

## 1. Context & Objectives

To overcome the Carrier-Grade NAT (CGNAT) barrier without exposing residential router ports directly to the public internet, Milestone v2.0 established a **Site-to-Site WireGuard Mesh** extending the on-premise Proxmox cluster to a public cloud gateway hosted in Google Cloud Platform (GCP).

---

## 2. Legacy Architecture Topology

![v2 Architecture](../images/v.2.0.0/P1.hybrid-network/architecture-topology.png)
![v2 Automation Pipeline](../images/v.2.0.0/P1.hybrid-network/automation-pipeline.png)

---

## 3. Implementation Stages & Failure Analysis

### Stage 1: The "Direct Connect" Attempt (Rejected)
- **Design:** Router port-forwarding on residential router.
- **Why Rejected:** Severe security risk. Exposing the private home network directly violated Zero Trust principles and created a massive reconnaissance surface.

### Stage 2: The "Split-Brain" Dynamic Cloud (Failed Experiment)
- **Design:** Provisioned GCP Spot VMs ($3/mo) paired with Dynamic DNS and custom bash watchdogs (`watchdog-vpn.sh`) to detect preemption, recreate VMs, and rewrite Ansible inventory files with `sed`.
- **Failure Modes:**
  - DNS propagation delays (5–10 minutes) caused external webhooks to drop silently during preemption events.
  - Ephemeral public IP reassignment broke Ansible static inventories with `Host Unreachable` errors.

### Stage 3: The Stable Cloud Gateway
- **Design:** Provisioned a persistent GCP `e2-micro` instance with a reserved static IP in GCP Mumbai (`asia-south1`).
- **Result:** Eliminated the circuit-breaker issue. If the homelab went offline, the cloud gateway served a clean HTTP 502 Bad Gateway page instead of raw TCP connection timeouts.

---

## 4. Architectural Comparison: Milestone v2.0 vs. Modern v3.0

| Feature / Domain | Milestone v2.0 (Hybrid Cloud Relay) | Milestone v3.0 (Sovereign Cloud Platform) |
| :--- | :--- | :--- |
| **Ingress Routing** | Cloud Nginx VM -> WireGuard Tunnel -> On-Prem Traefik. | Cloudflare Anycast Global Edge -> Outbound QUIC Tunnel -> On-Prem Traefik. |
| **Ingress Latency** | ~45ms to 120ms (cross-network proxy hops). | <15ms Anycast edge termination in Mumbai/Delhi/Chennai. |
| **Cloud Infrastructure Cost** | ~$7.50 to $12.00 / month (VM compute, static IP, egress). | Zero recurring ingress costs (leveraging Cloudflare Zero Trust Anycast tunnels). |
| **Secret Management** | Ansible Vault + Jinja2 Just-in-Time hydration (`hydrate_infra.yml`). | In-Git Mozilla SOPS encryption with Age asymmetric keys; decrypted in-memory by Flux CD. |
| **Continuous Delivery** | Imperative `ansible-playbook` & manual `kubectl apply`. | Fully declarative GitOps continuous reconciliation via Flux CD v2. |
| **Management Plane** | Intermediate SSH Jump Host (`ops-center` VM). | Direct Peer-to-Peer Tailscale WireGuard Mesh from engineer workstation to hypervisor. |

---

## 5. Architectural Decommissioning Rationale

While Milestone v2.0 successfully proved that hybrid cloud routing could bypass CGNAT, it carried high operational complexity:

1. **Recurring Infrastructure Overhead:** Maintaining a 24/7 cloud compute VM, external static IP, and cloud NAT incurred ongoing cloud fees.
2. **Intermediate Bastion Overhead:** Running `ops-center` as an intermediate SSH jump host and MinIO state server consumed 2GB RAM, 2 vCPUs, and 20GB NVMe storage on the physical host.
3. **Double Ingress Complexity:** Managing Nginx configurations in cloud VMs while simultaneously managing Traefik ingress definitions on-premise doubled the surface area for routing errors.

*These pain points directly led to ADR-006 (Cloudflare Zero Trust Ingress), ADR-011 (OCI Multi-Cloud Hybrid Support Architecture), and ADR-015 (Decommissioning of ops-center in favor of Direct Operations).*
