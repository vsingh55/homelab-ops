# 🛡️ Disaster Recovery: The 3-2-1 Implementation

**Goal:** Achieve a fully automated, "Zero-Touch" backup pipeline that survives a total server failure.

## 1. The "Push" Strategy (Server-Side)
Configured a Daily Backup Job in Proxmox.
* **Schedule:** Daily at 2:00.
* **Mode:** Snapshot (Zero downtime for running VMs).
* **Compression:** `ZSTD` (Selected over GZIP for multi-core performance).
* **Retention Policy:** `Keep Last: 7`, `Keep Weekly: 4`, `Keep Monthly: 2`.
    * *Why:* This specific policy balances safety with the limited 1TB capacity of the HDD.

## 2. The "Pull" Strategy (Client-Side)
I needed an offsite copy without paying for cloud storage. I turned my Fedora Laptop into a "Cold Storage" node.

### The Toolchain
* **Rclone:** Used for its robust sync capabilities over SFTP.
* **Systemd Timers:** Used instead of Cron.
    * *Challenge:* Cron jobs fail if the laptop is asleep at the scheduled time.
    * *Solution:* Systemd `Persistent=true` directive ensures the backup runs immediately when the laptop wakes up if a job was missed.

### The Automation Code
The synchronization logic is handled by a custom Bash script located in `~/.local/bin/`:

```bash
#!/bin/bash
# Mirrors Proxmox HDD to Local Laptop
# Uses --delete to ensure deleted server backups are removed locally to save space.
rclone sync proxmox-server:/mnt/hdd/dump ~/Backups/Homelab --progress --transfers 4