# Proxmox Foundation: The Base Layer

**Goal:** Configure a production-ready Hypervisor on consumer hardware (Mini PC).

## 1. Storage Architecture
To optimize for both speed (IOPS) and capacity, I implemented a tiered storage layout:

| Role | Physical Disk | Proxmox ID | File System | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Hot Tier** | 256GB NVMe SSD | \`local-lvm\` | LVM-Thin | Host OS, VM Boot Disks, Containers |
| **Cold Tier** | 1TB SATA HDD | \`HDD-Storage\` | ext4 | Backups, ISO Images, Templates |

### Implementation Details
The HDD was mounted via \`/etc/fstab\` to ensure persistence after reboot:
\`\`\`bash
UUID=<disk-uuid> /mnt/hdd ext4 defaults 0 2
\`\`\`

## 2. Cloud-Init Automation
To enable Infrastructure as Code (Terraform), I replaced manual ISO installs with a **Cloud-Init Template**.

**The "Golden Image" Build Process:**
1.  **Source:** Ubuntu 24.04 LTS Cloud Image (Generic).
2.  **modifications:**
    * Installed QEMU Guest Agent.
    * Enabled Serial Console (for Terraform logs).
    * Attached Cloud-Init drive (IDE2).
3.  **Result:** A template (ID 9000) that allows instant cloning with SSH keys pre-injected.

## 3. Notification System (Observability)
Proxmox does not support external SMTP by default. I configured a centralized relay to ensure critical alerts (Backup Failures, Disk Errors) reach my phone.

* **Target:** SMTP Relay (Gmail) via port 587 (STARTTLS).
* **Auth:** Google App Password (Zero-Trust approach).
* **Routing:** Configured a "Notification Matcher" to route all \`severity=error\` alerts to the external relay.


> Trust me all the things were so tempting i really enjoying the process.🤗