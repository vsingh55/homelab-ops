# Historical Engineering Archive (v1.0 & v2.0 Milestones)

> **Status:** Historical Reference & Engineering Post-Mortems  
> **Notice:** The documents in this section record the engineering evolution, technical challenges, and iterative migrations leading up to the current **Sovereign Cloud Platform (v3.0)**. For current production documentation, see [System Architecture](../architecture/01-system-overview.md).

---

## 🏛️ The Evolutionary Milestones

Systems engineering is an iterative discipline. The current zero-trust GitOps architecture was forged by identifying the pain points, performance bottlenecks, and technical debt of earlier versions:

### Milestone 1: Bare-Metal Foundation (v1.0)
* **[v1 Legacy Architecture: Bare-Metal & LXC Partitioning](v1-legacy-baremetal-foundation.md)** — Initial Proxmox VE virtualization, resource experiments, and early LXC container attempts.

### Milestone 2: The Hybrid Cloud Bridge (v2.0)
* **[v2 Legacy Hybrid Cloud Relay: GCP WireGuard Gateway](v2-legacy-hybrid-cloud-relay.md)** — Traversing CGNAT using a public cloud VM gateway, early MinIO remote state, and WireGuard site-to-site meshes.

---

## 🛠️ Engineering Journals & Incident Post-Mortems

A core philosophy of platform engineering is rigorous post-mortem documentation. These incident reports document real-world production outages, root causes, and corrective actions:

1. **[Incident Post-Mortem: Bare-Metal Boot Failure & GRUB Recovery](post-mortems/01-debugging-boot-failure.md)** — Diagnosing and recovering from root filesystem mount failure on Proxmox VE.
2. **[Incident Post-Mortem: Debugging WAN Connectivity & Gateway Routing](post-mortems/02-debugging-wan-connectivity.md)** — Resolving routing asymmetry and packet drop on residential gateways.
3. **[Technical Deep-Dive: Infrastructure Challenges](post-mortems/03-infrastructure-challenges.md)** — Early architectural constraints and storage bottlenecks.
4. **[Engineering Journey: Ansible Automation Fleet](post-mortems/04-ansible-automation-journey.md)** — Transitioning from imperative shell scripts to idempotent Ansible roles.
5. **[Engineering Journey: Terraform Modularization](post-mortems/05-terraform-modularization.md)** — Refactoring monolithic infrastructure code into reusable modules.
6. **[Technical Deep-Dive: In-Memory Secret Hydration](post-mortems/06-legacy-secret-hydration.md)** — The pre-GitOps "Hydration" pattern using Ansible Vault and ephemeral files.
7. **[Project Journal: Hybrid Cloud Automation with n8n](post-mortems/07-hybrid-cloud-automation-n8n.md)** — Building a self-hosted alternative to Zapier across cloud and on-premise environments.
8. **[Project Journal: Self-Healing VPN Watchdog](post-mortems/08-self-healing-watchdog.md)** — Developing automated recovery scripts to heal preempted cloud gateways.
