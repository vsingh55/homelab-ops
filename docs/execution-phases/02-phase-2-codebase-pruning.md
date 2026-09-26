# Phase 2 Execution Guide: Codebase Pruning & Inventory Restructuring

> **Phase Identifier:** PHASE-02 
> **Target Components:** `infrastructure/on-prem/`, `configuration/inventory/`, `configuration/playbooks/` 
> **Status:** Ready for Execution 
> **Prerequisites:** Phase 1 Completed ([01-phase-1-architecture-baseline.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/01-phase-1-architecture-baseline.md))

---

## 1. Executive Summary & Objective

Phase 2 cleanses the repository codebase by surgically removing all code, variables, playbooks, and inventory entries associated with:
1. **The Academy / Lab Zone:** (`gateway`, `jumpbox`, `server`, `node-0`, `node-1`) — completed certification renders this obsolete.
2. **The `ops-center` Management VM:** (`ops_center`) — replaced by direct laptop execution and OCI remote state.

At the conclusion of Phase 2, the Terraform infrastructure and Ansible configuration will define **strictly two target entities**:
- The bare-metal hypervisor: **`pve`** (`192.168.1.3` / Tailscale `100.108.178.93`).
- The production Kubernetes node: **`k3s-prod`** (`192.168.1.30`).

---

## 2. The "Why": Architectural Rationale & Risk Elimination

### A. Why Purge Rather Than Comment Out?
- **Git as the Sole Archive:** Git commit history preserves all previous code forever. Leaving commented-out blocks or inactive modules in active manifests creates technical debt, degrades linting, and leads to accidental re-provisioning.
- **Terraform Plan Clarity:** When running `terraform plan`, having 6 modules defined (5 of which are dead) produces 500+ lines of diff output, obscuring real changes to `k3s-prod`.
- **Ansible Execution Velocity:** The `ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q devops@ops-center"'` pattern forced every Ansible task targeting Proxmox to establish two nested SSH connections through `ops-center`. Removing this proxy hop cuts playbook execution time in half and eliminates the bastion as a single point of failure.

---

## 3. The "What": Concrete Code Modifications

```
Files Modified / Deleted in Phase 2:
├── infrastructure/on-prem/
│ ├── main.tf [MODIFY: Remove gateway, k8s_cluster, ops_center modules]
│ ├── variables.tf [MODIFY: Remove gateway_config, vms, ops_center_config]
│ └── terraform.tfvars.example [MODIFY: Remove Zone A and Zone M variables]
├── configuration/
│ ├── inventory/
│ │ ├── hosts.yml [MODIFY: Purge management, lab, gcp, vpn_clients groups]
│ │ └── group_vars/
│ │ ├── all/vars.yml [MODIFY: Remove proxmox_vms lab blocks]
│ │ └── hypervisor/vars.yml [MODIFY: Purge ProxyCommand through ops-center]
│ └── playbooks/
│ └── manage_lab.yml [DELETE: Obsolete lab power toggle playbook]
```

---

## 4. The "How": Step-by-Step Technical Execution

### Step 2.1: Prune `infrastructure/on-prem/main.tf`
Modify [infrastructure/on-prem/main.tf](file:///home/vsc/devlopment/myGH/homelab-ops/infrastructure/on-prem/main.tf) to retain **only** the production K3s VM module.

```hcl
# ==========================================================
# HOMELAB-OPS: ON-PREMISES PRODUCTION INFRASTRUCTURE
# ==========================================================

# Zone P: PROD (Application Plane - K3s)
module "k3s_prod" {
 source = "./modules/compute/vm"

 target_node = var.target_node
 vm_name = "k3s-prod"
 vmid = var.k3s_prod_config.vmid
 template_name = var.vm_template

 cores = var.k3s_prod_config.cores
 memory = var.k3s_prod_config.memory
 disk_size = var.k3s_prod_config.disk_size
 
# 1TB SATA HDD Data Disk Attachment (Cold Tier for Media, Books, Backups)
 data_disk_size = "800G"
 data_disk_storage = "backup-hdd"
 
 agent_enabled = 1
 onboot = var.k3s_prod_config.onboot

 ci_user = var.ci_user
 ssh_key = var.ssh_key
 ip_address = var.k3s_prod_config.ip
 gateway_ip = "192.168.1.1" # Physical Router IP
}
```

### Step 2.2: Prune `infrastructure/on-prem/variables.tf`
Remove the following unused variable blocks:
- `variable "passwordGW"`
- `variable "gateway_config"`
- `variable "vms"`
- `variable "ops_center_config"`

Retain only:
- `proxmox_api_url`, `proxmox_api_token_id`, `proxmox_api_token_secret`, `target_node`, `vm_template`, `ci_user`, `ssh_key`, and `k3s_prod_config`.

### Step 2.3: Restructure `configuration/inventory/hosts.yml`
Simplify [configuration/inventory/hosts.yml](file:///home/vsc/devlopment/myGH/homelab-ops/configuration/inventory/hosts.yml) to the clean, two-node inventory:

```yaml
all:
 children:
# -----------------------------------
# INFRASTRUCTURE (The Hypervisor)
# -----------------------------------
 hypervisor:
 hosts:
 pve:
 ansible_host: 192.168.1.3
 ansible_user: root

# -----------------------------------
# ZONE PROD (Kubernetes Application Plane)
# -----------------------------------
 production:
 hosts:
 k3s-prod:
 ansible_host: 192.168.1.30
 ansible_user: devops
```

### Step 2.4: Clean `configuration/inventory/group_vars/hypervisor/vars.yml`
Remove the `ansible_ssh_common_args` line:

```yaml
---
# Connection settings for Proxmox Node (Direct Tailscale / LAN)
pve_cluster_name: home-cluster
```

### Step 2.5: Delete `configuration/playbooks/manage_lab.yml`
Delete the obsolete lab power management playbook:
```bash
git rm configuration/playbooks/manage_lab.yml
```

---

## 5. Verification & Validation Commands

Execute the following checks from your laptop:

### Check 1: Terraform Syntax Validation
```bash
cd infrastructure/on-prem
terraform validate
```
*Expected Output:* `Success! The configuration is valid.`

### Check 2: Ansible Inventory Verification
```bash
cd configuration
ansible-inventory -i inventory/hosts.yml --list
```
*Expected Output:* Valid JSON output containing only groups `hypervisor` and `production`.

### Check 3: Direct Connectivity Ping (No Bastion)
```bash
cd configuration
ansible -i inventory/hosts.yml -m ping all
```
*Expected Output:* Both `pve` and `k3s-prod` return `"ping": "pong"` with `SUCCESS`.

---

## 6. Failure Modes & Rollback Strategy

| Failure Mode | Root Cause | Immediate Remediation |
| :--- | :--- | :--- |
| `terraform validate` fails with missing variable | Variable referenced in output or module was purged | Check `outputs.tf` in `infrastructure/on-prem/` and remove references to `gateway` or `ops_center` |
| `ansible -m ping pve` fails with permission denied | Root SSH key mismatch | Verify laptop's `~/.ssh/id_ed25519.pub` is present in Proxmox `/root/.ssh/authorized_keys` |

- **Rollback Procedure:** If needed, revert code changes using Git:
 ```bash
 git checkout main -- infrastructure/on-prem/ configuration/
 ```
