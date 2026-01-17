# Project - Hybrid Cloud Automation (n8n)

## 1. The Mission

**Objective:** Build a professional-grade "Sovereign Cloud" platform to automate workflows (e.g., Infrastructure Automation, Disaster Recovery Verification, Document Intelligence) without relying on expensive SaaS subscriptions or purely public cloud infrastructure.  
**Constraint:** The system must run workloads On-Premises (Home Lab) but accept traffic securely from the Public Internet (GitHub Webhooks).

---

## 2. Architecture Evolution

### Phase 1: The "Direct Connect" Attempt (Naive)

* **Design:** Port Forwarding on Home Router.
* **Why Rejected:** Security risk. Exposing the home network directly to the internet violates "Zero Trust" principles.

### Phase 2: The "Split-Brain" Dynamic Cloud (Experimental)

* **Design:** GCP Spot VM acting as a Gateway.
* Automated "Watchdog" scripts to heal the infrastructure when GCP killed the VM.
* Dynamic DNS updates via Cloudflare API.


* **Challenges Encountered:**
* **"Zombie" State:** The VM would restart, but DNS propagation took time, causing webhook failures.
* **Complexity Debt:** Maintaining bash scripts (`watchdog-vpn.sh`) became more complex than the infrastructure itself.
* **Ansible Drift:** The inventory file frequently had the varrying IP, breaking (slowing) down automation pipelines.



### Phase 3: The "Stable Mesh" (Production Grade)

* **Design:**  
  *  **Hub:** GCP Standard VM (Static IP) in Mumbai (`asia-south1`).
  * **Spoke:** K3s Cluster on Proxmox (Home).
  * **Tunnel:** WireGuard Mesh VPN (Peer-to-Peer).
  * **Storage:** Longhorn/LocalPath with MinIO + Velero for Disaster Recovery.


* **Why Chosen:**
  * **Stability:** A reserved Static IP eliminates the need for dynamic DNS scripts.
  * **Latency:** Choosing Mumbai over US (despite higher cost) ensures the control plane feels "local" (30ms vs 250ms).
  * **Resilience:** If the Home Lab goes down, the Cloud Gateway acts as a "Circuit Breaker" (502 Bad Gateway) rather than a connection timeout.

---

## 3. Technical Challenges & Solutions

| Challenge | Symptom | Root Cause | Solution |
| --- | --- | --- | --- |
| **The Routing Loop** | `wg-quick` service failed to start | WireGuard `AllowedIPs` included the LAN subnet (`192.168.0.0/24`), causing the kernel to route local traffic into the tunnel. | Refined Ansible templates to only route VPN overlay traffic (`10.100.0.0/24`) through the tunnel. |
| **The "Zombie" Pod** | n8n crashed with `Connection Refused` | n8n started before Postgres was ready or after a restore without data. | Implemented **Velero** for backups and fixed `chmod 777` permissions on PVCs to allow the restore helper to write data. |
| **WebSocket Failure** | "Lost Connection to Server" in n8n UI | Nginx Proxy was stripping `Upgrade` and `Connection` headers. | Updated Nginx template to support WebSocket Protocol upgrades (`proxy_set_header Upgrade $http_upgrade;`). |
| **Split-Brain Network** | Ansible `Unreachable` / 504 Gateway Timeout | Spot VM was preempted, changing the IP, but Inventory wasn't updated. | Migrated to **Static IP** + **Standard VM** to ensure infrastructure immutability. |

---

## 4. Current State 

* **Infrastructure:** Fully managed via Terraform (GCP) and Ansible (On-Prem).
* **Security:** SSL Auto-Termination (Certbot/Let's Encrypt) at the Edge.
* **Observability:** Ready for Prometheus/Grafana integration, GitOps integration.
* **Backup:** Automated snapshots to S3-compatible storage (MinIO).

