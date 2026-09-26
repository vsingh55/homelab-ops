# Milestone v2.0: The Hybrid Cloud Relay Bridge (Legacy)

> **Status:** Historical Milestone (Superseded by Sovereign Cloud v3.0) 
> **Original Timeframe:** Milestone v2.0 Architecture 
> **Key Technologies:** GCP Compute Engine, WireGuard Site-to-Site, MinIO on ops-center 

---

## 1. Context & Objectives

To overcome the Carrier-Grade NAT (CGNAT) barrier without exposing residential ports directly to the internet, Milestone v2.0 established a **Site-to-Site WireGuard Mesh** extending the on-premise Proxmox cluster to a public cloud gateway in Google Cloud Platform (GCP).

---

## 2. Legacy Architecture Topology

![v2 Architecture](../images/v.2.0.0/P1.hybrid-network/architecture-topology.png)
![v2 Automation Pipeline](../images/v.2.0.0/P1.hybrid-network/automation-pipeline.png)

---

## 3. The Implementation Stages & Lessons Learned

### Stage 1: The "Direct Connect" Attempt (Naive)
- **Design:** Port forwarding on residential router.
- **Why Rejected:** Severe security risk. Exposing the private home network directly violated Zero Trust principles.

### Stage 2: The "Split-Brain" Dynamic Cloud (Experimental)
- **Design:** GCP Spot VM as a gateway + custom Bash watchdog scripts (`watchdog-vpn.sh`) to restart the VM and rewrite Ansible inventory with `sed` when preempted.
- **Failure Modes:** DNS propagation delays caused webhook drops. Dynamic IP changes caused severe Ansible inventory drift.

### Stage 3: The Stable Cloud Gateway
- **Design:** Standard VM with static IP in GCP Mumbai (`asia-south1`).
- **Result:** Eliminated the circuit-breaker issue. If the homelab went down, the gateway served a clean 502 error instead of connection timeouts.

---

## 4. Why Milestone v2.0 Was Modernized in v3.0

1. **Recurring Cloud Costs:** Maintaining a 24/7 GCP Compute instance, external static IP, and Cloud NAT incurred monthly recurring cloud charges (~$10–$15/mo).
2. **Intermediate Bastion Overhead:** Running `ops-center` as an intermediate SSH jump host and MinIO state server consumed 2GB RAM, 2 vCPUs, and 20GB NVMe storage.
3. **Cross-Continental Latency:** Ingress routing added unnecessary latency hops compared to edge Anycast routing.

*These pain points led to ADR-006 (Cloudflare Zero Trust Ingress), ADR-011 (OCI Mumbai Always Free Support), and ADR-015 (Decommissioning of ops-center in favor of Direct Operations).*
