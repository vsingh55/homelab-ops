# Runbook: Backup & Disaster Recovery Operations

| Operational Parameter | Production Specification |
| :--- | :--- |
| **Document Classification** | Platform Operations & Disaster Recovery (DR) Runbook |
| **Recovery Time Objective (RTO)** | < 45 Minutes (Full Bare-Metal Reconstruction) / < 5 Minutes (Stateful Failover) |
| **Recovery Point Objective (RPO)** | < 15 Minutes (PostgreSQL Continuous WAL) / < 24 Hours (Hypervisor Snapshot) |
| **Backup Hierarchy** | Gold-Standard 3-2-1 Topology (NVMe Hot -> SATA Cold -> OCI Mumbai Offsite) |
| **Target Infrastructure** | Proxmox VE 8.x, K3s Kubernetes, CloudNativePG, Restic, OCI Object Storage |
| **Relevant Decisions** | [ADR-002](../adr/README.md#adr-002), [ADR-010](../adr/README.md#adr-010), [ADR-011](../adr/README.md#adr-011) |

---

## 1. Operational Overview & 3-2-1 Backup Hierarchy

The platform implements an immutable, geographically independent **3-2-1 Backup Hierarchy** engineered to protect all application state, relational databases, media archives, and hypervisor configurations against physical drive failure, data corruption, and catastrophic bare-metal loss.

```
Disaster Recovery Architecture:
[ Production Workloads (k3s-prod) ]
      ├── Primary PostgreSQL Master (Tier 1: NVMe Flash)
      │     └── Continuous streaming WAL archiving (<15m RPO)
      ▼
[ Tier 2: Local Mechanical SATA Storage (/mnt/hdd/dump/) ]
      ├── Daily Proxmox vzdump VM block-level snapshots (ZSTD compressed)
      ├── Barman object store WAL archives
      └── Paperless & BookOrbit media volumes
      ▼
[ Tier 3: Offsite Multi-Cloud Storage (OCI Mumbai ap-mumbai-1) ]
      ├── S3 Object Storage Bucket: homelab-backups
      ├── Client-side encrypted via Restic (AES-256-GCM)
      └── Retained across 30-day rolling snapshot policy
```

---

## 2. Daily Health Verification Check

Execute the following routine operational checks to verify backup parity and repository integrity:

### 1. Verify Local Hypervisor Snapshots
```bash
# Check latest vzdump snapshots on the Proxmox host
ssh root@100.108.178.93 "ls -lh /mnt/hdd/dump/"
```
*Expected Output:* Confirms daily `.vma.zst` files exist with non-zero size and recent timestamps.

### 2. Verify CloudNativePG WAL Archiving
```bash
# Verify database cluster health and continuous backup status
kubectl get cluster -n database postgres-ha -o wide
```
*Expected Output:* Status `Cluster in healthy state`, `Continuous Backup: OK`.

### 3. Audit Remote Restic Offsite Snapshots (OCI Mumbai)
```bash
# Inspect offsite encrypted snapshot repository
restic -r s3:https://<OCI_NAMESPACE>.compat.objectstorage.ap-mumbai-1.oraclecloud.com/homelab-backups snapshots
```
*Expected Output:* Lists snapshots matching the nightly backup schedule with zero reported integrity errors.

---

## 3. Disaster Recovery Playbooks

### Playbook A: Single Pod or Application Namespace Deletion
*Trigger:* An operator accidentally deletes an application namespace or deployment.

**Remediation:** GitOps Continuous Delivery handles this automatically:
```bash
# Force immediate Flux CD v2 reconciliation from Git origin/main
flux reconcile kustomization apps --with-source
```
Flux detects the deleted resources within 60 seconds and redeploys the declared manifests directly from Git without manual intervention.

---

### Playbook B: Database Table Corruption / Point-in-Time Recovery (PITR)
*Trigger:* Data corruption, dropped table, or ransomware attack on relational database.

**Remediation Procedure:**
1. Identify the target recovery timestamp (prior to the corruption event, e.g. `2026-09-26 10:15:00 UTC`).
2. Create a restore cluster manifest pointing to the Barman WAL archive:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-recovered
  namespace: database
spec:
  instances: 2
  bootstrap:
    recovery:
      source: postgres-ha
      recoveryTarget:
        targetTime: "2026-09-26 10:15:00 UTC"
  storage:
    size: 20Gi
    storageClass: local-path
```

3. Apply the restore manifest. CloudNativePG replays base backups and Write-Ahead Logs up to the exact requested minute.
4. Update application database endpoints to target `postgres-recovered-rw`.

---

### Playbook C: Single VM Failure (`k3s-prod` VMID 500)
*Trigger:* Kernel panic, root disk corruption, or unbootable guest OS on VM 500.

**Remediation Procedure:**

1. Connect to Proxmox VE over the Tailscale administrative mesh:
```bash
ssh root@100.108.178.93
```

2. Stop the failed virtual machine:
```bash
qm stop 500 --skiplock 2>/dev/null || true
```

3. Identify the latest valid local snapshot:
```bash
ls -lt /mnt/hdd/dump/vzdump-qemu-500-*.vma.zst | head -n 3
```

4. Restore the virtual machine to NVMe flash storage:
```bash
qmrestore /mnt/hdd/dump/vzdump-qemu-500-<LATEST_DATE>.vma.zst 500 --storage local-lvm --force
```

5. Power on the restored instance:
```bash
qm start 500
```

6. Re-sync live Git state:
```bash
ssh devops@192.168.1.30 "kubectl get nodes"
flux reconcile source git flux-system
flux reconcile kustomization platform --with-source
flux reconcile kustomization apps --with-source
```

---

### Playbook D: Total Bare-Metal Host Destruction
*Trigger:* Physical motherboard death, electrical surge, fire, or catastrophic drive loss.

**Remediation Procedure:**

1. **Hardware Replacement:** Procure replacement x86-64 machine (min 16GB RAM, NVMe SSD, SATA drive).
2. **Install Hypervisor:** Flash Proxmox VE 8.x from USB onto NVMe root drive.
3. **Configure Network & Mesh:** Install Tailscale and join the secure administrative overlay.
4. **Mount Secondary Disk:** Format secondary SATA storage and mount to `/mnt/hdd/`.
5. **Pull Remote Cloud Snapshot:** Retrieve latest encrypted backup dump from OCI Object Storage using Restic:
```bash
export AWS_ACCESS_KEY_ID="<OCI_CUSTOMER_ACCESS_KEY>"
read -sp "Enter OCI Customer Secret Key: " AWS_SECRET_ACCESS_KEY && export AWS_SECRET_ACCESS_KEY

restic -r s3:https://<OCI_NAMESPACE>.compat.objectstorage.ap-mumbai-1.oraclecloud.com/homelab-backups \
  restore latest --target /mnt/hdd/dump/
```
6. **Restore Production VM:** Run `qmrestore /mnt/hdd/dump/vzdump-qemu-500-*.vma.zst 500 --storage local-lvm`.
7. **Boot VM & Automatic Ingress Recovery:** Power on VM 500. As soon as K3s initializes, `cloudflared` automatically dials outbound to Cloudflare Anycast edge servers, restoring public endpoints without DNS propagation delays. Total Recovery Time: **< 45 Minutes**.

---

## 4. Post-Restoration Verification Checklist

- [ ] Node status confirms `Ready` via `kubectl get nodes`.
- [ ] Database cluster reports healthy via `kubectl get cluster -n database`.
- [ ] Public endpoints respond with `HTTP 200` via `curl -I https://docs.vijaysingh.cloud`.
- [ ] Out-of-band Uptime Kuma probe in OCI Mumbai turns green and dispatches recovery notification to Slack `#homelab-alerts`.
