# Homelab-Ops: From Bare Metal to Cloud Native

**Role:** DevOps Engineer | Cloud Engineer | System Admin

**Stack:** Proxmox, Terraform, Ansible, Kubernetes, Docker

## Project Goal
To engineer a production-grade, self-hosted infrastructure that simulates a real-world enterprise environment. 
<!-- The focus is on **Data Sovereignty**, **Infrastructure as Code (IaC)**, and **Disaster Recovery**. -->

## Architecture
* **Hardware:** Mini PC (Intel i5 7th Gen, 16GB RAM, 256GB NVMe, 1TB HDD).
  ![alt text](/images/server.jpeg)
* **Hypervisor:** Proxmox VE 9.1 (Debian-based).
* **Storage Strategy:** Tiered architecture (NVMe for Hot Data/VMs, HDD for Cold Storage/Backups).
* **Backup Strategy:** 3-2-1 Rule implemented via Proxmox Snapshots + Offsite Rclone Sync.

## Engineering Journal
This repository documents the entire lifecycle of the lab:
### Documentation Overview

1. [Architecture & Storage Design](docs/01-architecture.md) — Resource-optimised architecture and tiered storage strategy tailored for constrained hardware, including capacity planning and performance tuning.
2. [Proxmox Foundation](docs/02-proxmox-setup.md) — Proxmox VE installation and hardening, Cloud‑Init VM templates, and network design/segmentation best practices.
3. [Disaster Recovery Pipeline](docs/03-backup-dr.md) — End-to-end automated backup and recovery workflows: snapshot policies, offsite encrypted sync with rclone, and systemd-based orchestration for zero-touch recovery.
4. [Infrastructure Provisioning (Terraform)](docs/04-infrastructure-provisioning.md) — Infrastructure-as-Code workflows, module development, state management, and troubleshooting strategies for provisioning and resource allocation.

## Key Technologies

| Layer | Tool | Purpose |
| :--- | :--- | :--- |
| Hypervisor | Proxmox VE | Host virtualization and VM lifecycle management |
| Provisioning | Terraform | Declarative infrastructure provisioning and drift control |
| Orchestration | Kubernetes | Container orchestration and workload management |
| Configuration Management | Ansible | System configuration and consistent state enforcement |
| VM Bootstrapping | Cloud‑Init | Automated VM templating and first-boot provisioning |
| Backup & Recovery | Rclone + systemd | Encrypted offsite sync and scheduled backup orchestration |
| Container Runtime | Docker | Local container image management and runtime |
| **Scripting** | Bash / Systemd | Automation of client-side sync tasks |
| **Networking** | SMTP Relay | Centralized Notification System (Gmail) |
| **Security** | Rclone (SFTP) | Encrypted transport of backups |

---
*This project is actively maintained.*