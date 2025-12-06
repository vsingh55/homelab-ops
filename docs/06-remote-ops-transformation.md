# 06. The Remote Operations Transformation

**Phase:** Operations & Security Hardening

## 1. The Challenge: "Works on My Machine"
Initially, the infrastructure state (`terraform.tfstate`) was trapped on my local laptop. This created two critical risks:
1.  **Single Point of Failure:** If the laptop disk failed, the knowledge of the infrastructure map was lost.
2.  **Concurrency Locks:** There was no mechanism to prevent multiple processes from modifying infrastructure simultaneously (State Locking).
3.  **Access Limits:** The lab was only accessible when physically connected to the home LAN.

## 2. The Solution: Remote State Backend (S3)
To align with IT Standards for data sovereignty and resilience, I implemented a self-hosted Object Storage solution.

* **Technology:** MinIO (S3 Compatible).
* **Deployment:** Containerized on the `ops-center` management node.
* **Architecture:**
    * Terraform is reconfigured to use the `s3` backend.
    * State files are stored in the `terraform-state` bucket.
    * **Result:** The "Brain" of the infrastructure is now decoupled from the control node (laptop).

## 3. The "Air Gap" Network Strategy (Zero Trust)
Exposing the Proxmox host port 8006 or SSH port 22 directly to the internet via Router Port Forwarding is a security violation.

**Implementation:**
* **Tailscale Mesh:** Installed on `ops-center` and the Control Node (Laptop).
* **Subnet Router:** Configured `ops-center` to act as a gateway (`--advertise-routes=192.168.0.0/24`).
* **DNS:** Enforced `1.1.1.1` (Cloudflare) via Tailscale Global Nameservers for privacy.
* **Outcome:** I can now `ping Internal-servers ` from a coffee shop without exposing any ports on the home router.

## 4. Next Steps
* **Production Cluster:** Deploy K3s for hosting persistent tools (Traefik, Grafana).
* **Observability:** Implement Prometheus for metrics collection.