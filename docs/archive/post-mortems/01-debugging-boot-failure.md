# Incident Post-Mortem: Bare-Metal Root Filesystem Corruption & Emergency Boot Recovery

> **Incident Classification:** Production Infrastructure Outage  
> **Incident ID:** INC-2026-01-03-P1  
> **Status:** Resolved & Permanently Remediated  

---

## Executive Metadata

| Attribute | Specification |
| :--- | :--- |
| **Incident Date** | 2026-01-03 |
| **Severity Level** | P1 (Critical - Core Management Infrastructure Unreachable) |
| **Affected System** | `ops-center` (VM 100 - Primary Operations & Management Host) |
| **Incident Commander** | Vijay Singh (Platform & DevOps Engineer) |
| **Time to Detect (TTD)** | 5 Minutes (Automated ping monitor alert) |
| **Time to Mitigate (TTM)** | 35 Minutes (LVM volume activation and manual fsck execution) |
| **Time to Recover (TTR)** | 45 Minutes (Kernel parameter automation codified and verified) |
| **Skills Deployed** | Linux Kernel Diagnostics, LVM Administration, GRUB Bootloader Tuning, Ansible IaC |

---

## 1. Executive Summary & Business Impact

Following an abrupt residential grid power cut and subsequent power restoration, the primary operations virtual machine (`ops-center`) failed to boot into Debian GNU/Linux. All automated management workflows, Terraform remote state access, and administrative SSH sessions timed out.

Direct hypervisor VNC console inspection revealed that the Linux kernel had panicked during the root mount sequence, dropping into an emergency `(initramfs)` diagnostic shell due to uncommitted filesystem metadata corruption on the LVM logical volume.

The incident was successfully resolved by activating the dormant LVM volume groups in the rescue environment, repairing filesystem inconsistencies with `fsck`, and permanently re-architecting the OS kernel parameters to enforce autonomous self-healing on boot.

---

## 2. Incident Timeline

| Timestamp | Elapsed Time | Event / Action Taken | Status |
| :--- | :--- | :--- | :--- |
| **14:15 UTC** | T+00m | Grid power outage strikes physical Mini PC host; hardware shuts down abruptly. | Impact |
| **14:22 UTC** | T+07m | Power restored. Physical Proxmox VE hypervisor boots successfully; VM 100 autostarts. | Detection |
| **14:27 UTC** | T+12m | Automated probe detects SSH timeout on `ops-center` (`192.168.0.5:22` OfflineError). | Investigation |
| **14:32 UTC** | T+17m | Platform engineer opens Proxmox noVNC console; discovers VM halted at `(initramfs)` prompt. | Triage |
| **14:40 UTC** | T+25m | Initial `fsck` fails due to inactive LVM volumes; engineer runs `lvm vgchange -ay` to register block devices. | Remediation |
| **14:48 UTC** | T+33m | Filesystem repaired with `fsck -y`; VM rebooted; SSH access restored. | Mitigation |
| **14:55 UTC** | T+40m | Cloud-Init GRUB priority conflict diagnosed; custom override drop-in engineered. | Hardening |
| **15:00 UTC** | T+45m | Self-healing parameters codified into Ansible `bootstrap.yml`; VM reboot verified. | Resolved |

---

## 3. Technical Root Cause Analysis (RCA)

### Root Cause 1: Dirty Filesystem Shutdown
Because power was abruptly severed, the ext4 filesystem journaling subsystem was unable to flush dirty page cache buffers from host RAM to the underlying NVMe storage pool. On reboot, the kernel detected an inconsistent superblock state and halted the boot sequence to avoid cascading data corruption.

```text
Target error message:
The root filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv requires a manual fsck.
```

### Root Cause 2: Inactive LVM Volumes in Emergency Shell
When dropped into the emergency `initramfs` busybox shell, the kernel had loaded physical disk drivers (`/dev/sda`, `/dev/nvme0n1`) but had not invoked the LVM2 userspace subsystem. Direct execution of `fsck /dev/mapper/ubuntu--vg...` threw device-not-found errors because the logical volume was in a suspended/inactive state.

### Root Cause 3: SSH Host Key Regeneration Mismatch
During intermediate troubleshooting, re-triggering Cloud-Init re-provisioned new SSH host keys on the guest VM. When connecting from the administrative workstation, SSH immediately aborted with:

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```
The workstation's cached `~/.ssh/known_hosts` fingerprint conflicted with the newly generated host key, requiring fingerprint cache purging before administrative automation could reconnect.

### Root Cause 4: Cloud-Init GRUB Configuration Precedence
Manual additions to `/etc/default/grub` were wiped upon executing `update-grub`. Investigation revealed that the cloud image shipped with `/etc/default/grub.d/50-cloudimg-settings.cfg`, which was lexicographically evaluated *after* the base configuration, silently overriding custom kernel arguments.

---

## 4. Remediation & Recovery Execution

### Step 1: Emergency Volume Group Activation & Repair
From within the Proxmox VNC emergency `(initramfs)` console, the LVM volume group was explicitly brought online:

```bash
# Activate all inactive LVM volume groups
lvm vgchange -ay

# Execute automated filesystem consistency check and repair
fsck -y /dev/mapper/ubuntu--vg-ubuntu--lv

# Exit initramfs and resume normal boot
exit
```

### Step 2: Workstation SSH Fingerprint Purge
The stale cryptographic fingerprints were evicted from the operator's workstation:

```bash
ssh-keygen -R ops-center
ssh-keygen -R 192.168.0.5
ssh-keygen -R 100.108.178.93
```

---

## 5. Permanent Corrective Actions (Preventative Engineering)

To guarantee that future ungraceful shutdowns never strand nodes in an emergency shell requiring manual keyboard intervention, a persistent kernel parameter override was codified.

### Action 1: Codifying High-Precedence GRUB Configuration
A dedicated drop-in file named `99-self-healing.cfg` was engineered to ensure it is evaluated last in `/etc/default/grub.d/`:

```bash
# /etc/default/grub.d/99-self-healing.cfg
GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 fsck.mode=force fsck.repair=yes"
```

- **`fsck.mode=force`**: Mandates a complete filesystem integrity check during the boot sequence regardless of clean bit markers.
- **`fsck.repair=yes`**: Automatically supplies non-interactive affirmative confirmation to all non-destructive journal repairs.

### Action 2: Infrastructure as Code Integration
The configuration was committed to the core Ansible `bootstrap.yml` playbook, guaranteeing automatic re-application on all current and future virtual machines:

```yaml
- name: "System | Codify Auto-FSCK Kernel Self-Healing"
  ansible.builtin.copy:
    dest: /etc/default/grub.d/99-self-healing.cfg
    owner: root
    group: root
    mode: "0644"
    content: |
      # MANAGED BY ANSIBLE (homelab-ops)
      GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 fsck.mode=force fsck.repair=yes"
  notify: Update GRUB
```

---

## 6. Post-Mortem Lessons & Architectural Directives

1. **Autonomous Recovery Over Manual Triage:** Infrastructure must be architected to self-heal from power events. Relying on an engineer to open a hypervisor console defeats the purpose of an autonomous platform.
2. **Beware of Vendor Cloud-Init Defaults:** Upstream cloud images frequently overwrite base system configuration files. All custom kernel and network overrides must use explicit numbered drop-in directories (`*.d/`).
3. **Hardware Resiliency Evolution:** This incident demonstrated that software-level filesystem self-healing is a prerequisite for reliable edge computing, directly influencing the single-node consolidation strategy adopted in Milestone v3.0.