# 13. Debugging VM Boot Failure (Filesystem Corruption)

**Date:** 2026-01-03  
**Severity:** P1 (Critical - Infrastructure Down)  
**Affected System:** `ops-center` (Management Node)  
**Status:** Resolved ✅

**Incident:** `ops-center` VM stuck in emergency mode (initramfs) after power failure; SSH unreachable.

**Skills Deployed:** Linux System Administration, LVM Management, GRUB Bootloader Tuning, Infrastructure as Code (Ansible).

## 1. The Incident
**Observation:**
After a power cut and restoration, the `ops-center` VM failed to come online.
* **Remote Access:** SSH timed out (`OfflineError`).
* **Console Output:** The Proxmox console showed the VM dropped into an `(initramfs)` shell with the error:
  > *The root filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv requires a manual fsck.*

**Initial Hypothesis:**
Abrupt power loss prevented the OS from flushing write buffers to the disk, leaving the filesystem "dirty." The Linux kernel detected this inconsistency and paused the boot process to prevent data loss.

## 2. The Investigation

### Step 1: The "Chicken and Egg" LVM Problem
Attempting to run `fsck` immediately failed because the device path `/dev/mapper/ubuntu--vg...` did not exist.
* **Analysis:** In the emergency shell, Logical Volume Management (LVM) is not active by default. The kernel sees the physical disk (`/dev/sda`) but not the logical partitions containing the data.
* **Action:** We had to manually wake up the volume group:
  ```bash
  lvm vgchange -ay  # Activate all volumes
  ```

Only then did the device appear, allowing us to run the repair: `fsck -y /dev/mapper/ubuntu--vg-ubuntu--lv`.

### Step 2: The "Identity Crisis" (SSH Lockout)

After fixing the disk and regenerating the Cloud-Init image (to reset credentials), SSH access failed again with:

> *WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!*

* **Root Cause:** Regenerating Cloud-Init created new SSH Host Keys for the VM. The control node (Laptop) still had the old keys cached in `known_hosts`, flagging the connection as a potential Man-in-the-Middle attack.
* **Fix:** Cleared the stale fingerprints:
```bash
ssh-keygen -R ops-center
ssh-keygen -R 192.168.0.5
ssh-keygen -R 100.x.x.x  # Replace with actual IP
```

### Step 3: The Persistence Failure (Cloud-Init Override)

I attempted to enable auto-repair by editing `/etc/default/grub`, but the settings vanished after `update-grub`.

* **Discovery:** The command output revealed that a separate file, `50-cloudimg-settings.cfg`, was sourcing *after* our main config and overwriting our changes.
* **Lesson:** On Cloud Images, the default config files are often second-class citizens.

## 3. The Solution

### Fix 1: The "Self-Healing" Boot Configuration

To prevent manual intervention in future power cuts, i engineered the kernel to fix filesystem errors automatically.

I created a "Super-Override" file (`99-self-healing.cfg`) to ensure our settings take precedence over Cloud-Init defaults.

**Configuration:**

```bash
GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 fsck.mode=force fsck.repair=yes"

```

* `fsck.mode=force`: Check disk integrity on every boot.
* `fsck.repair=yes`: Automatically answer "Yes" to all repair prompts.

### Fix 2: Infrastructure as Code (Ansible)

Instead of relying on manual edits, I codified this resilience into the `bootstrap.yml` playbook. This ensures that even if i destroy and recreate the VM using Terraform, the self-healing capability is immediately applied.

```yaml
- name: "System | Enable Auto-FSCK Self-Healing"
  copy:
    dest: /etc/default/grub.d/99-self-healing.cfg
    content: |
      # HOMELAB-OPS MANAGED FILE
      GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 fsck.mode=force fsck.repair=yes"
  notify: update_grub
```
### Verification

1. Ran Ansible: `ansible-playbook playbooks/bootstrap.yml --limit ops-center`
2. Rebooted VM.
3. Checked Kernel Parameters:
```bash
cat /proc/cmdline
# Output includes: fsck.mode=force fsck.repair=yes
```

## 4. Outcome

**Resilience:** The infrastructure is now resilient to hard power cuts. The boot time increased slightly (~30s) for self-checks, but availability is guaranteed without human intervention.

**Compliance:** Moved from "Hobbyist" manual fixes to "Engineering Standard" automated configuration management.