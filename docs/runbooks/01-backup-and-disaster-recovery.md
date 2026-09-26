# Runbook: Backup & Disaster Recovery Operations

> **Classification:** Production Operations Runbook  
> **Recovery Target (RTO):** < 45 Minutes  
> **Data Loss Target (RPO):** < 24 Hours (Nightly Snapshots)  
> **Scope:** Bare-Metal Proxmox Host, K3s Production VM, Stateful Databases  

---

## 1. Operational Overview

This runbook outlines the operational procedures for verifying, maintaining, and executing recovery procedures across the platform's **3-2-1 Backup Hierarchy**:

1. **Tier 1 (Hot In-Cluster):** Continuous Write-Ahead Log (WAL) archiving via CloudNativePG.
2. **Tier 2 (Local SATA HDD):** Nightly Proxmox `vzdump` snapshots stored in `/mnt/hdd/dump/`.
3. **Tier 3 (Offsite Cloud):** Nightly AES-256 encrypted Restic backups synchronized to Oracle Cloud Infrastructure (OCI) Object Storage.

---

## 2. Daily Health Verification Check

Run the following checks to verify backup health:

```bash
# 1. Check local backup snapshots on Proxmox VE
ssh root@100.108.178.93 "ls -lh /mnt/hdd/dump/"

# 2. Verify CloudNativePG PostgreSQL backup and WAL archiving status
kubectl get cluster -n platform -o wide

# 3. Check Restic remote repository snapshots on OCI Object Storage
restic -r s3:https://<OCI_NAMESPACE>.compat.objectstorage.ap-mumbai-1.oraclecloud.com/restic-repo snapshots
```

---

## 3. Disaster Recovery Scenario A: Single VM Failure (`k3s-prod`)

If the `k3s-prod` virtual machine becomes corrupted or unbootable:

### Step 1: Identify the Latest Healthy Snapshot
```bash
ssh root@100.108.178.93
# List snapshots sorted by date
ls -lt /mnt/hdd/dump/vzdump-qemu-500-*.vma.zst | head -n 3
```

### Step 2: Restore the Virtual Machine
```bash
# Stop the failed VM if still running
qm stop 500

# Restore VM from local backup dump onto NVMe storage pool
qmrestore /mnt/hdd/dump/vzdump-qemu-500-YYYY_MM_DD.vma.zst 500 --storage local-lvm --force

# Start the restored VM
qm start 500
```

### Step 3: Verify Cluster & GitOps Reconciliation
```bash
# Wait for the K3s API to become ready
kubectl get nodes

# Trigger immediate Flux reconciliation to sync any commits made since the snapshot
flux reconcile kustomization platform --with-source
flux reconcile kustomization apps --with-source
```

---

## 4. Disaster Recovery Scenario B: Total Bare-Metal Host Rebuild

If the physical Mini PC suffers a catastrophic hardware failure:

1. **Hardware Replacement:** Procure replacement x86-64 machine (min 16GB RAM, NVMe + SATA storage).
2. **Install Proxmox VE 8:** Install base Proxmox VE 8 from USB ISO onto primary NVMe disk.
3. **Mount Storage Pools:** Formatted secondary drive mounted to `/mnt/hdd`.
4. **Restore Remote Backups:** Fetch latest `vma.zst` snapshot archive from OCI Object Storage using Restic:
   ```bash
   restic -r s3:<OCI_S3_ENDPOINT>/restic-repo restore latest --target /mnt/hdd/dump/
   ```
5. **Restore & Boot VM 500:** Run `qmrestore` and power on `k3s-prod`.
6. **Verify Cloudflare Ingress:** As soon as `k3s-prod` powers on, `cloudflared` automatically reconnects to the Anycast edge, restoring public traffic without DNS propagation delays.
