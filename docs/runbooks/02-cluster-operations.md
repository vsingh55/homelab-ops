# Runbook: Day-2 Cluster Operations & Maintenance

| Operational Parameter | Production Specification |
| :--- | :--- |
| **Document Classification** | Platform Engineering Day-2 Standard Operating Procedures (SOP) |
| **Target Infrastructure** | K3s Production Cluster (`k3s-prod`), Proxmox VE 8.x, Flux CD v2, Mozilla SOPS |
| **Primary Toolchains** | `flux`, `sops`, `age`, `kubectl`, `ansible`, `terraform` |
| **Relevant Decisions** | [ADR-005](../adr/README.md#adr-005), [ADR-007](../adr/README.md#adr-007), [ADR-008](../adr/README.md#adr-008) |

---

## 1. Declarative Secret Management (Mozilla SOPS & Age)

All sensitive credentials (database passwords, API tokens, webhook keys) are encrypted inside Git manifests using **Mozilla SOPS** and the platform's public **Age** key. Plaintext secrets are strictly prohibited from touching disk or Git commits.

### Encrypting a New Secret Manifest
1. Generate standard unencrypted Kubernetes Secret manifest:
```bash
kubectl create secret generic n8n-credentials \
  --from-literal=encryption-key="super-secure-generated-key" \
  --dry-run=client -o yaml > secret.yaml
```

2. Encrypt in-place using SOPS (matching rules defined in [`.sops.yaml`](https://github.com/vsingh55/homelab-ops/blob/main/.sops.yaml)):
```bash
sops --encrypt --in-place secret.yaml
```

3. Rename to follow the encrypted secret standard ([`kubernetes/apps/n8n/secrets.enc.yaml`](https://github.com/vsingh55/homelab-ops/blob/main/kubernetes/apps/n8n/secrets.enc.yaml)):
```bash
mv secret.yaml kubernetes/apps/n8n/secrets.enc.yaml
```

### Editing an Existing Encrypted Secret
To update values in an already-encrypted secret without creating plaintext temporary files:
```bash
# Opens decrypted manifest in your default terminal editor ($EDITOR)
# Automatically re-encrypts upon save and clean exit
sops kubernetes/apps/n8n/secrets.enc.yaml
```

### Age Keypair Backup & Disaster Recovery
The master Age private key is stored inside K3s in the `flux-system` namespace. To take an encrypted backup of the cluster private key:
```bash
# Pull Age private key from cluster
kubectl -n flux-system get secret sops-age -o jsonpath="{.data['age\.agekey']}" | base64 -d > sops-age.key

# Store securely in offline password manager (Bitwarden / 1Password)
# Immediately wipe local plain file
shred -u sops-age.key
```

---

## 2. GitOps Continuous Delivery & Reconciliation (Flux CD v2)

Flux automatically synchronizes the cluster state against `origin/main` every 10 minutes. For rapid verification or immediate deployment, execute manual reconciliation:

### Triggering Immediate Layer Synchronization
```bash
# 1. Force Git source repository update
flux reconcile source git flux-system

# 2. Force platform layer reconciliation (CRDs, ingress, operators)
flux reconcile kustomization platform --with-source

# 3. Force application layer reconciliation (workloads, databases)
flux reconcile kustomization apps --with-source
```

### Auditing Reconciliation Status & Drift
```bash
# View summary table of all active Kustomizations
flux get kustomizations

# Stream real-time reconciliation events and error logs
flux events --all-namespaces
```

### Reverting an Erroneous Deployment
Because all state is declared in Git, reverting a broken configuration does not require manual `kubectl` intervention:
```bash
# Revert commit on workstation
git revert <COMMIT_HASH>
git push origin main

# Force immediate sync or wait for 60-second webhook trigger
flux reconcile source git flux-system
```

---

## 3. Node Maintenance, Kernel Updates & Graceful Host Reboot

Host and guest patching is automated through the **Autonomous Sysadmin Maintenance Engine** ([`playbooks/sysadmin_maintenance.yml`](https://github.com/vsingh55/homelab-ops/blob/main/configuration/playbooks/sysadmin_maintenance.yml)), with inventory managed in [`inventory/hosts.yml`](https://github.com/vsingh55/homelab-ops/blob/main/configuration/inventory/hosts.yml). Manual commands are retained as an emergency fallback.

### Method A: Automated Sysadmin Maintenance Engine (Recommended)

Execute the end-to-end maintenance pipeline across the bare-metal hypervisor, production K3s VM, and cloud monitoring node:

```bash
cd configuration/ # (https://github.com/vsingh55/homelab-ops/tree/main/configuration)

# 1. Run safe security patch maintenance (Non-disruptive, preserves minor/major kernel pins)
ansible-playbook -i inventory/hosts.yml playbooks/sysadmin_maintenance.yml

# 2. (Optional) Run full dist-upgrade explicitly during scheduled maintenance windows
ansible-playbook -i inventory/hosts.yml playbooks/sysadmin_maintenance.yml -e "security_only=false"
```

**Automated Guardrail Pipeline:**
1. **Pre-flight Assertion:** Asserts $\ge$ 3GB free root partition space before downloading packages.
2. **Health Probe:** Validates K3s cluster node status is `Ready` before touching any system packages.
3. **Non-Interactive Patching:** Enforces `--force-confdef --force-confold` to eliminate interactive prompt hangs.
4. **Coordinated Drain:** Automatically detects `/var/run/reboot-required`. If a reboot is required, it cordons and drains `k3s-prod` with `--ignore-daemonsets --delete-emptydir-data --force` before triggering `reboot`.
5. **Recovery & Stabilization:** Reconnects post-reboot, uncordons the node, and polls `kubectl get pods -A` until all pods report `Running`.
6. **Disk Hygiene:** Runs `crictl rmi --prune`, cleans APT cache, and vacuums systemd logs older than 14 days.
7. **Audit Notification:** Dispatches a structured status embed to Discord.

---

### Method B: Manual Fallback Procedure (Emergency Only)

If Ansible is unavailable, perform manual maintenance sequentially:

#### Step 1: Cordon and Drain the Kubernetes Node
```bash
# Prevent new pods from being scheduled onto k3s-prod
kubectl cordon k3s-prod

# Gracefully evict non-daemonset pods with emptyDir allowance
kubectl drain k3s-prod --ignore-daemonsets --delete-emptydir-data --force
```

#### Step 2: Apply OS Updates on Hypervisor
```bash
ssh root@100.108.178.93
apt-get update && apt-get dist-upgrade -y

# Verify running kernel and reboot if required
needrestart -b || reboot
```

#### Step 3: Uncordon Node & Verify Workload Health
```bash
# Allow pods to be scheduled again
kubectl uncordon k3s-prod

# Verify all pods return to Running state with zero restarts
kubectl get pods -A
```

---

## 4. Storage Maintenance & Disk Hygiene

The physical Mini PC operates on a dual-tier storage strategy (256GB NVMe SSD + 1TB SATA mechanical HDD). Maintain disk hygiene with the following procedures:

### Inspecting Storage Utilization
```bash
# SSH into k3s-prod
ssh devops@192.168.1.30

# Check NVMe flash utilization (root) and SATA HDD utilization (/mnt/hdd)
df -h / /mnt/hdd
```

### Pruning Dangling Container Images & Build Cache
K3s includes automated image garbage collection, but manual cleanup can be forced if disk usage exceeds 80%:
```bash
# Remove unused container images and build layers
sudo k3s crictl rmi --prune
```

### Scrubbing Local Backup Archives
Local Proxmox VM snapshots are retained on the mechanical HDD for 7 days. Verify retention policy:
```bash
ssh root@100.108.178.93 "find /mnt/hdd/dump/ -type f -mtime +14 -name '*.vma.zst' -delete"
```
