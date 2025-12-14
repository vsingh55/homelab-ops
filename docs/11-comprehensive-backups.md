# Comprehensive Backup Strategy
**Goal:** Achieve a "Zero Data Loss" architecture by backing up both the **Platform** (Kubernetes) and the **Management Plane** (Ops-Center).

## Strategy Overview
We adhere to a **3-Layer Defense Strategy** to ensure work continuity for the homelab.

| Layer | Scope | Tool | Storage Location | Frequency |
| :--- | :--- | :--- | :--- | :--- |
| **1. Infrastructure** | VM OS, Network Config, Partition Tables | **Proxmox Snapshots** | Local ZFS / HDD | Daily, Weekly, Monthly |
| **2. Application** | K8s Manifests, PVCs (Databases), Secrets | **Velero** | MinIO (S3) | Daily |
| **3. Data & Config** | MinIO Data, Terraform State, Code Repos | **Restic** | Local HDD (`/var/backups`) | Daily @ 03:00 |

---

### Layer 1: Infrastructure (Disaster Recovery)
*See `03-backup-dr.md` for Proxmox Snapshot details.*

---

### Layer 2: Kubernetes Applications (Velero)
We use **Velero** to perform "Cluster-Aware" backups. This protects the logical application state (Deployments, Services) and persistent data (PVCs).

#### Installation
Velero is installed via the Ansible role `backup-velero`.
* **Namespace:** `velero`
* **Provider:** AWS (MinIO compatible)
* **Plugin:** `velero-plugin-for-aws`

#### How to Manage
**Trigger Manual Backup:**
```bash
velero backup create manual-backup-name --kubeconfig ~/.kube/config-k3s-prod
```
**Restore an Application:**  If the grafana namespace is deleted:
```Bash
velero restore create --from-backup scheduled-backup-name --include-namespaces grafana
```
### Layer 3: Host Data & Configs (Restic)
Since MinIO (holding Layer 2 backups) and Terraform State run on ops-center, we must protect the ops-center filesystem itself.

**Tool: Restic** I used Restic orchestrated by a custom Ansible role (ops-center-backup).

**Repository:** /var/backups/ops-center-repo

**Encryption:** Secured via Ansible Vault password.

### What is Backed Up?
**MinIO Data Directory:** /mnt/storage/minio-data (Critical)

**Code Repository:** /home/devops/homelab-ops

**Shell Configuration:** .zshrc, .zsh_secrets

**Automation**
A cron job runs at 03:00 AM daily via /usr/local/bin/run-ops-center-backup.

**Retention Policy**: Keep last 7 Daily, last 4 Weekly.

**Verification**
To check the status of host backups (requires root):

```Bash
sudo -i
export RESTIC_REPOSITORY="/var/backups/ops-center-repo"
export RESTIC_PASSWORD="YOUR_VAULT_PASSWORD"
restic snapshots
```


## Implementation: Velero (K8s Layer)
I created an Ansible role (`backup-velero`) to deploy the Velero Server into `k3s-prod` and target the local MinIO instance.

### Challenge A: Missing Kubeconfig
**Symptom:** Ansible failed with `Invalid kube-config file. No configuration found.`

**Context:** The `ops-center` was running the playbook, but the `k3s-prod` config was on a different node (`server`).

**Solution:**
1.  **Key Exchange:** Copied the SSH key from my laptop to `ops-center` so it could talk to the cluster nodes.
2.  **Fetch & Patch:** Used SSH to fetch `/etc/rancher/k3s/k3s.yaml` from the master node and `sed` to replace `127.0.0.1` with the master's LAN IP.

### Challenge B: Missing Python Dependency
**Symptom:** Ansible failed to check for existing deployments: `Failed to import the required Python library (kubernetes)`.

**Solution:** Added a pre-task to the role to install `python3-kubernetes` via apt using `become: true`.

## Implementation: Restic (Host Layer)
Since `ops-center` hosts the "Brain" of the lab (MinIO + Code), I created the `ops-center-backup` role.

**What gets backed up?**
* `/mnt/storage/minio-data` (The S3 buckets containing Terraform state).
* `/home/devops/homelab-ops` (The git repository).
* `/home/devops/.zshrc` (Shell configuration).

### Challenge C: Cron & Permissions
**Symptom:** Running `restic snapshots` as the `devops` user failed because the repo was owned by `root`.
**Solution:**
* **Automation:** Configured a root Cron Job to run the backup script at **03:00 AM**.
* **Manual Access:** Documented that manual checks must be done via `sudo -i` with explicitly exported environment variables.

## Final Architecture
* **Automation:** Terraform provisions the Storage HDD -> Ansible mounts it -> Ansible installs Velero/Restic -> Cron triggers daily backups.
* **Security:** All backup passwords are stored in **Ansible Vault**, never in plain text.