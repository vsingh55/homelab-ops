# 07. The Automation Journey: From Shell to Ansible

**Scope:** Configuration Management & Orchestration

## 1. The Problem: "Configuration Drift"
After provisioning VMs with Terraform, I faced the operational challenge. Manually SSH-ing into 5 different servers to install updates, Docker, and users is:
1.  **Error-Prone:** Missing a step on `node-1` creates a broken cluster.
2.  **Unscalable:** Adding a 4th node would require repeating all manual steps.
3.  **Insecure:** Storing SSH passwords in text files or typing them repeatedly.

## 2. The Solution: Ansible (Agentless Architecture)
We chose Ansible because it requires no agents on the target VMs—only SSH. This fits perfectly with our "Air Gapped" architecture where the Management Node acts as the central control plane.

### Architecture
* **Control Node:** Laptop (Fedora) - Writes and triggers code.
* **Managed Nodes:**
    * `ops-center` (Management Zone)
    * `k3s-prod` (Production Zone)
    * `server`, `node-x` (Lab Zone)
* **Transport:** SSH Pipelining via Tailscale.

## 3. Key Challenges & Solutions

### Challenge A: The "Chicken and Egg" Connectivity
**Issue:** The internal VMs (`192.168.0.x`) are behind a NAT/Firewall. The Laptop (on Tailscale `100.x`) cannot reach them directly to configure them.

**Solution:** The **Jump Host Pattern**.
We configured Ansible to transparently tunnel connections through the `ops-center`.
* *Config:* `inventory/group_vars/lab.yml`
* *Code:* `ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q devops@ops-center"'`

### Challenge B: Hardcoded Secrets
**Issue:** API keys and database passwords cannot be stored in plain text YAML files committed to GitHub.
**Solution:** **Ansible Vault**.
All sensitive variables are encrypted using AES-256.
* *Usage:* `ansible-vault encrypt_string 'MySecretPass'`

### Challenge C: Resource Constraints (RAM)
**Issue:** Running the "Production Cluster" and "Lab Cluster" simultaneously exceeds the host's 16GB RAM.
**Solution:** **Zone Switching**.
We implemented a `manage_lab.yml` playbook that talks to the Hypervisor API to programmatically start/stop the "Lab Zone" when not in use.

## 4. Current State
* **Inventory:** Dynamic YAML inventory (`hosts.yml`) separated by Zones.
* **Roles:**
    * `minio`: Deploys Object Storage for Terraform State.
    * `bootstrap`: Standardizes OS hygiene (Docker, Users, Tools).