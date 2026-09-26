# Historical Engineering Archive & Incident Post-Mortem Register

> **Platform Standard:** Historical Engineering Milestones, Outage Post-Mortems & Architectural Retrospectives  
> **Status:** Archival Reference (Milestone v1.0 & v2.0)  
> **Notice:** The documents in this section record the iterative engineering journey, production outage post-mortems, and technical debt remediations leading to the current **Sovereign Cloud Platform (v3.0)**. For active production architecture, see [System Architecture](../architecture/01-system-overview.md).

---

## 1. Platform Evolutionary Milestones

Systems engineering is an iterative discipline. The current zero-trust GitOps architecture was forged by identifying the operational pain points, performance bottlenecks, and security trade-offs of earlier platform iterations:

| Milestone | Architecture Foundation | Ingress & Networking | State & Secret Management | Key Limitations & Catalyst for Evolution |
| :--- | :--- | :--- | :--- | :--- |
| **Milestone v1.0** | Proxmox VE bare-metal, dual LXC containers, manual K3s setup. | Isolated residential LAN; zero external inbound ingress. | Local unencrypted files; plain environment variables. | Heavy RAM fragmentation; unable to ingest external webhooks; manual configuration drift. |
| **Milestone v2.0** | Hybrid Cloud Relay: GCP e2-micro gateway + On-prem K3s VM. | Public cloud VM proxying traffic over site-to-site WireGuard mesh. | Ansible Vault encryption with just-in-time Jinja2 hydration; MinIO state. | High cross-continental proxy latency; recurring cloud NAT costs; intermediate bastion operational overhead. |
| **Milestone v3.0** | Sovereign Cloud Platform: Single consolidated K3s VM on Proxmox VE. | Cloudflare Zero Trust Anycast edge tunnels (<15ms latency, zero open ports). | Declarative GitOps via Flux CD v2; in-Git Mozilla SOPS encryption with Age keys. | **Current Production Standard:** Fully automated, self-healing, zero inbound attack surface, high-durability 3-2-1 backup topology. |

### Architectural Retrospective Documents:
- **[Milestone v1.0 Architecture: Bare-Metal Foundation & LXC Zoning](v1-legacy-baremetal-foundation.md)** — Hypervisor initialization, storage pool partitioning, and early virtualization trade-offs.
- **[Milestone v2.0 Architecture: Hybrid Cloud Relay Bridge](v2-legacy-hybrid-cloud-relay.md)** — Traversing CGNAT using a public cloud VM gateway, early MinIO remote state, and WireGuard site-to-site meshes.

---

## 2. Production Incident Post-Mortems & Technical Journals

A foundational pillar of platform engineering is blameless, rigorous post-mortem documentation. The following reports document real-world outages, root cause analyses (RCA), and permanent corrective actions executed across the infrastructure:

| Incident / Case Study | Classification | Severity | Affected Scope | Root Cause Summary |
| :--- | :--- | :--- | :--- | :--- |
| **[Boot Failure & GRUB Recovery](post-mortems/01-debugging-boot-failure.md)** | Production Outage | P1 (Critical) | `ops-center` Management VM | Sudden power cut caused uncommitted filesystem metadata corruption; initramfs shell blocked boot pending LVM activation and fsck. Codified `fsck.repair=yes` into Ansible bootstrap. |
| **[Asymmetric WAN Routing](post-mortems/02-debugging-wan-connectivity.md)** | Network Degraded | P2 (Major) | Remote Admin Access | Split-horizon DNS conflict: local SSH client configuration directed remote management packets to non-routable LAN IPs instead of the Tailscale overlay mesh. |
| **[Terraform & Proxmox State Drift](post-mortems/03-infrastructure-challenges.md)** | Provisioning Failure | P3 (Moderate) | IaC Pipeline | Declarative omission of explicit disk blocks caused Terraform to detach cloned VM disks post-creation; resolved by enforcing explicit SCSI definitions in HCL. |
| **[Ansible Automation Fleet Journey](post-mortems/04-ansible-automation-journey.md)** | Technical Retrospective | P3 (Moderate) | Config Management | Migration from fragile imperative shell scripts to idempotent Ansible playbooks with jump-host proxying and dynamic RAM zone allocation. |
| **[Terraform Modularization Architecture](post-mortems/05-terraform-modularization.md)** | Technical Retrospective | P3 (Moderate) | IaC Codebase | Refactoring monolithic `main.tf` into DRY reusable modules utilizing dynamic disk allocation blocks and remote MinIO S3 state backend. |
| **[Just-In-Time Secret Hydration Pattern](post-mortems/06-legacy-secret-hydration.md)** | Security Architecture | P2 (Major) | Secret Lifecycle | Bridge architecture between Ansible Vault and Terraform using in-memory templates prior to adopting in-Git Mozilla SOPS in v3.0. |
| **[Hybrid Cloud Automation with n8n](post-mortems/07-hybrid-cloud-automation-n8n.md)** | Case Study | P2 (Major) | Workflow Engine | Engineering a self-hosted, sovereign Zapier alternative bridging cloud webhooks with on-premise execution nodes across WireGuard tunnels. |
| **[Self-Healing Host Watchdog](post-mortems/08-self-healing-watchdog.md)** | Resilience Case Study | P2 (Major) | Host Disk & Docker | Engineering an automated container watchdog monitoring physical disk thresholds and executing scoped remediation routines via least-privilege SSH keys. |

---

## 3. Engineering Tenets Derived from Historical Failures

1. **Explicit Over Implicit Configuration:** Declarative infrastructure orchestrators (Terraform, Flux) must have fully explicit resource definitions; omitting blocks leads to unexpected resource destruction.
2. **Deterministic Automated Recovery:** Manual intervention during power outages or system restarts is unacceptable. All hosts must self-heal filesystem anomalies without requiring emergency console intervention.
3. **Defense-in-Depth Identity:** Never rely on network boundary trust alone. All administrative paths must enforce end-to-end encryption, multi-factor authentication, and strict least-privilege access controls.
