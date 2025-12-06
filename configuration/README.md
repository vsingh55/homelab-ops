# Configuration Management (Ansible)

This directory handles the operations: bootstrapping OS, installing software (Docker/K3s), and managing configuration drift.

# Configuration Management (Ansible)

This directory contains the "Day 2" operational logic for the Homelab. It handles Operating System bootstrapping, software installation (Docker, MinIO), and secret management across the infrastructure.

## Directory Structure

```bash
.
├── ansible.cfg             # Core Ansible configuration (Inventory path, Roles path)
├── inventory/              # The Source of Truth for infrastructure
│   ├── hosts.yml           # Defines hosts and groups (Management, Production, Lab/Kubernetes)
│   └── group_vars/         # Variables applied to specific groups
│       ├── all.yml         # Global settings (Python interpreters, SSH users)
│       ├── production.yml         # Variables for the k3s-prod persistent cluster
│       ├── lab.yml  # K8s-specific settings (Jump Host tunneling args)
│       └── management/     # Management node settings (includes Vaulted secrets)
├── playbooks/              # Entry points for automation tasks
│   ├── bootstrap.yml       # Initial OS setup (Updates, Dependencies, Docker)
│   └── deploy_minio.yml    # Deploys the MinIO Object Storage container
│   └── manage_lab.yml    # Automates the Power On/Off of the "Lab Zone" to save RAM.
└── roles/                  # Reusable logic units
    └── minio/              # Role to install and configure MinIO S3
```

## Security Model
* **Jump Host:** The control node (Laptop) connects ONLY to `ops-center` via Tailscale.
* **Tunneling:** Connection to internal VMs (`192.168.0.x`) is tunneled through `ops-center`.
* **Secrets:** Sensitive data (passwords) is encrypted with `ansible-vault`.

## Workflows
**Verification:** Ensure Ansible can reach all nodes (tunnels are working)
```bash
ansible -m ping all
```
**Bootstrapping:** Prepares a fresh Ubuntu VM for production use. Installs Docker, standard utilities (curl, git, jq), and configures user permissions.
```bash
ansible-playbook playbooks/bootstrap.yml
```
**Deploying S3 Storage (MinIO):** Deploys the MinIO container on the Management node to serve as the remote backend for Terraform state.
```bash
ansible-playbook playbooks/deploy_minio.yml --ask-vault-pass
```

**Start the Lab (Academy Zone):**
```bash
ansible-playbook playbooks/manage_lab.yml --tags start_lab
```
**Stop the Lab (Save RAM):**
```bash
ansible-playbook playbooks/manage_lab.yml --tags stop_lab
```