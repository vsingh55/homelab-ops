# Phase 2: Codebase Pruning & Inventory Restructuring

| Milestone Attribute | Engineering Specification |
| :--- | :--- |
| **Phase Scope** | Codebase Cleansing, IaC Simplification & Inventory Restructuring |
| **Target Infrastructure** | Infrastructure as Code (Terraform) & Configuration Management (Ansible) |
| **Primary Code Paths** | [`infrastructure/on-prem/`](file:///home/vsc/devlopment/myGH/homelab-ops/infrastructure/on-prem/), [`configuration/inventory/`](file:///home/vsc/devlopment/myGH/homelab-ops/configuration/inventory/) |
| **Relevant Decisions** | [ADR-005](../adr/README.md#adr-005), [ADR-015](../adr/README.md#adr-015), [ADR-016](../adr/README.md#adr-016) |
| **Operational Status** | Production Verified (Platform v3.0.0) |

---

## 1. Executive Summary & Objective

Phase 2 cleanses the platform codebase by surgically removing all Terraform resources, variables, Ansible playbooks, and inventory entries associated with:
1. **The Academy / Lab Zone:** (`gateway`, `jumpbox`, `server`, `node-0`, `node-1`) — completed certification rendered these definitions obsolete.
2. **The `ops-center` Bastion:** (`ops_center`) — replaced by direct laptop execution and offsite OCI remote state.

At the conclusion of Phase 2, the Terraform infrastructure and Ansible inventory define **strictly two target entities**:

- The bare-metal hypervisor: **`pve`** (`192.168.1.3` / Tailscale `100.108.178.93`).
- The production Kubernetes node: **`k3s-prod`** (`192.168.1.30`).

---

## 2. Engineering Rationale: Why Purge Rather Than Comment Out?

1. **Git as the Sole Immutable Archive:** Git commit history preserves all previous configurations. Leaving commented-out blocks or inactive modules in production manifests creates technical debt, degrades linters, and risks accidental re-provisioning.
2. **Terraform Plan Clarity:** When executing `terraform plan`, having 6 modules defined (5 of which are dead) produces 500+ lines of diff noise, obscuring genuine modifications to `k3s-prod`.
3. **Ansible Execution Velocity:** The legacy `ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q devops@ops-center"'` pattern forced every task targeting Proxmox to establish two nested SSH hops through `ops-center`. Removing this proxy hop cut execution time in half and eliminated the bastion single point of failure.

---

## 3. Concrete Code Modifications

```
Repository Changes in Phase 2:
├── infrastructure/on-prem/
│   ├── main.tf                 [MODIFIED: Retain only module.k3s_prod]
│   ├── variables.tf            [MODIFIED: Purged gateway_config, vms, ops_center_config]
│   └── terraform.tfvars.example [MODIFIED: Simplified to bare-metal & k3s-prod]
├── configuration/
│   ├── inventory/
│   │   ├── hosts.yml           [MODIFIED: Reduced to hypervisor & production groups]
│   │   └── group_vars/
│   │       └── hypervisor/vars.yml [MODIFIED: Purged ProxyCommand through ops-center]
│   └── playbooks/
│       └── manage_lab.yml      [DELETED: Obsolete lab power toggle playbook]
```

---

## 4. Technical Execution Details

### 1. Pruning `infrastructure/on-prem/main.tf`
The on-premises root manifest was streamlined to declare strictly the production K3s VM with its dedicated compute, memory, and secondary 1TB SATA HDD data mount:

```hcl
# Zone P: Production Kubernetes Application Plane
module "k3s_prod" {
  source = "./modules/compute/vm"

  target_node   = var.target_node
  vm_name       = "k3s-prod"
  vmid          = var.k3s_prod_config.vmid
  template_name = var.vm_template

  cores         = var.k3s_prod_config.cores
  memory        = var.k3s_prod_config.memory
  disk_size     = var.k3s_prod_config.disk_size
  
  # Secondary SATA HDD Mount (Cold Tier for Media, Books, Backups)
  data_disk_size    = "800G"
  data_disk_storage = "backup-hdd"
  
  agent_enabled = 1
  onboot        = var.k3s_prod_config.onboot

  ci_user       = var.ci_user
  ssh_key       = var.ssh_key
  ip_address    = var.k3s_prod_config.ip
  gateway_ip    = "192.168.1.1" # Physical Router Gateway
}
```

### 2. Restructuring `configuration/inventory/hosts.yml`
The Ansible inventory was reduced from complex nested bastion groups into a flat, deterministic topology:

```yaml
all:
  children:
    # Bare-Metal Hypervisor
    hypervisor:
      hosts:
        pve:
          ansible_host: 192.168.1.3
          ansible_user: root

    # Production Kubernetes Workload Plane
    production:
      hosts:
        k3s-prod:
          ansible_host: 192.168.1.30
          ansible_user: devops
```

### 3. Deleting Obsolete Operational Scripts
```bash
git rm configuration/playbooks/manage_lab.yml
```

---

## 5. Verification & Quality Assertions

The following commands confirm codebase purity and operational reachability:

### 1. Terraform Syntax Validation
```bash
cd infrastructure/on-prem
terraform validate
# Output: Success! The configuration is valid.
```

### 2. Ansible Inventory Structure Audit
```bash
cd configuration
ansible-inventory -i inventory/hosts.yml --list
# Output: Valid JSON containing exclusively 'hypervisor' and 'production' groups.
```

### 3. Direct Node Connectivity Verification
```bash
cd configuration
ansible -i inventory/hosts.yml -m ping all
# Output: Both pve and k3s-prod return "ping": "pong" with SUCCESS via direct connection.
```

---

## 6. Exit Gate & Phase Transition

With all dead code purged, Terraform manifests validated, and Ansible inventory simplified to the two operational nodes, the platform proceeded to **[Phase 3: Multi-Cloud Remote State Backend Architecture](03-remote-state-migration.md)** to establish offsite state locking.
