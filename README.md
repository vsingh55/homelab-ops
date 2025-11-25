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
1.  [**Architecture & Storage Design**](docs/01-architecture.md) - Optimization of limited resources.
2.  [**Proxmox Foundation**](docs/02-proxmox-setup.md) - Base hardening, Cloud-Init templates, and Networking.
3.  [**Disaster Recovery Pipeline**](docs/03-backup-dr.md) - Automated "Zero-Touch" backup systems using Systemd & Rclone.

## 🚀 Key Technologies
| Layer | Tool | Usage |
| :--- | :--- | :--- |
| **Hypervisor** | Proxmox VE | Virtualization Management |
| **Automation** | Cloud-Init | VM Templating & Bootstrapping |
| **Scripting** | Bash / Systemd | Automation of client-side sync tasks |
| **Networking** | SMTP Relay | Centralized Notification System (Gmail) |
| **Security** | Rclone (SFTP) | Encrypted transport of backups |

---
*This project is actively maintained. Next Phase: Infrastructure provisioning via Terraform.*