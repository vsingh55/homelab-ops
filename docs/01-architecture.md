# Architecture & Resource Strategy

## 1. The Constraint Challenge
**Scenario:** I had a single Mini PC with 16GB RAM. Running a full Kubernetes cluster + Production services requires careful resource budgeting.
**Solution:** Implemented a **"Two-Layer Architecture"**.
* **Zone A (Production):** Lightweight LXC Containers for critical services (Gateway, DNS, IAM), running other open source tools for personal uses. Low overhead.
* **Zone B (Academy):** Full VMs for "Kubernetes The Hard Way" labs. Can be spun down to save RAM.

## 2. Storage Topology
One of the biggest challenges was the mismatched drives (256GB SSD vs 1TB HDD).
* **The Mistake:** Initially, the 1TB drive was unmounted, and backups were filling up the small SSD root partition.
* **The Fix:**
    * **NVMe (local-lvm):** Reserved strictly for OS and VM Disks (Speed).
    * **HDD (HDD-Storage):** Mounted via `fstab` to `/mnt/hdd`. Configured Proxmox to use this *only* for ISOs and Backups.
    * **Result:** High IOPS for apps, massive capacity for archives.