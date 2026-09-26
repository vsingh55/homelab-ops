# Technical Post-Mortem: Terraform-to-Proxmox State Drift & Provisioning Race Conditions

> **Incident Classification:** Infrastructure as Code (IaC) Engineering Post-Mortem  
> **Incident ID:** INC-2025-12-15-P3  
> **Status:** Resolved & Architectural Standard Codified  

---

## Executive Metadata

| Attribute | Specification |
| :--- | :--- |
| **Incident Date** | 2025-12-15 |
| **Severity Level** | P3 (Moderate - Automated Provisioning Pipeline Interrupted) |
| **Affected Subsystem** | Proxmox VE Virtual Machine Provisioning (`Telmate/proxmox` Provider) |
| **Primary Tooling** | Terraform v1.5+, Proxmox VE 8.x API, Cloud-Init Ubuntu 22.04 Templates |
| **Incident Commander** | Vijay Singh (Platform & DevOps Engineer) |
| **Resolution Status** | Fully Remediated via Explicit Modular HCL Declarations |

---

## 1. Executive Summary

During the initial automation of virtual machine provisioning on Proxmox VE, several severe edge-case anomalies emerged between the Infrastructure as Code engine (Terraform) and the hypervisor QEMU API. Virtual machines provisioned without throwing syntax errors, but subsequently failed to boot with "No Bootable Device" or aborted during execution due to missing network interfaces and schema rejections.

Deep-dive debugging at the hypervisor API and QEMU configuration level identified three interconnected root causes: **declarative disk detachment (The Ghost Disk Phenomenon)**, **boot order race conditions**, and **breaking API schema validation in upstream provider release candidates**.

This post-mortem details the forensic analysis, QEMU configuration mechanics, and permanent code architecture refactors that resolved the failure modes.

---

## 2. Technical Anomaly 1: The "Ghost Disk" Phenomenon

### Symptom & Behavior
Terraform reported a successful `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` However, when the hypervisor attempted to boot the newly created VM, the SeaBIOS console immediately threw:

```text
Booting from Hard Disk...
Boot failed: not a bootable disk
No bootable device.
```

### Forensic Analysis & Root Cause
In Proxmox, cloning a VM template (`clone = "ubuntu-cloud-template"`) copies the template's underlying QCOW2 or raw virtual disk. 

Because Terraform is a strictly declarative orchestrator:
1. The developer omitted an explicit `disks { ... }` block in the HCL, assuming the cloned disk would persist implicitly.
2. Terraform's reconciliation engine compared the active state (which had a cloned disk) with the desired state (which specified zero disks).
3. To enforce convergence with the code, the provider issued an API command immediately after cloning to **detach the disk**, unlinking it from the VM bus and leaving an empty virtual machine.

### Remediation & Code Diff
An explicit disk management block was codified in the Terraform compute module, binding the cloned drive to the SCSI controller and locking its persistence:

```diff
  resource "proxmox_vm_qemu" "vm" {
    name        = var.vm_name
    target_node = var.target_node
    clone       = var.template_name

+   disks {
+     scsi {
+       scsi0 {
+         disk {
+           storage = var.storage_pool
+           size    = var.disk_size
+           format  = "raw"
+         }
+       }
+     }
+   }
  }
```

---

## 3. Technical Anomaly 2: Boot Order Race Condition

### Symptom & Behavior
During subsequent provisioning runs, Terraform crashed during resource creation with an unhandled provider panic:

```text
Error: error updating VM: invalid bootorder: device 'net0' does not exist
  with proxmox_vm_qemu.k8s_node["node-1"],
  on main.tf line 42, in resource "proxmox_vm_qemu" "k8s_node":
  42: resource "proxmox_vm_qemu" "k8s_node" {
```

### Root Cause Analysis
Similar to the storage detachment, the HCL configuration defined:
```hcl
boot = "order=scsi0;net0"
```
However, the configuration lacked an explicit `network { ... }` block. The Proxmox provider purged the cloned network adapter during phase 1 of reconciliation. In phase 2, when the provider evaluated the `boot` string directive, it attempted to map the boot priority to `net0`. Because `net0` had just been destroyed, the Proxmox API rejected the request with an invalid device error.

### Remediation
Codified an explicit VirtIO network interface block within the compute module, establishing an unbroken dependency sequence:

```hcl
network {
  model  = "virtio"
  bridge = "vmbr0"
  tag    = -1 # Untagged management traffic
}
boot = "order=scsi0;net0"
```

---

## 4. Technical Anomaly 3: Provider Schema Strictness (`v3.0.2-rc04`)

### Symptom & Behavior
After upgrading the `Telmate/proxmox` provider to `3.0.2-rc04` to unlock compatibility with Proxmox VE 8 kernel privilege checks, previously working manifests failed with schema validation errors:

```text
Error: Missing required argument
  on modules/compute/vm/main.tf line 18:
  18: network {
The argument "id" is required, but no definition was found.
```

### Root Cause Analysis
Previous stable provider releases (v2.9.x) dynamically assigned sequential numerical identifiers (`net0`, `net1`) to network interfaces behind the scenes. The `v3.0.x` release candidate eliminated auto-indexing in favor of explicit schema enforcement, requiring every defined network block to supply an explicit integer `id`.

### Remediation
Refactored the network configuration within `modules/compute/vm/main.tf` to explicitly pass zero-indexed interface IDs:

```hcl
network {
  id     = 0
  model  = "virtio"
  bridge = var.network_bridge
}
```

---

## 5. Architectural Principles Derived

| Anti-Pattern Identified | Engineering Best Practice Implemented |
| :--- | :--- |
| **Implicit Resource Inheritance:** Assuming cloned virtual hardware will persist without being declared in code. | **Total Declarative Explicitness:** Every disk, NIC, bus controller, and core must be explicitly enumerated in HCL. |
| **Unpinned Provider Upgrades:** Using floating version constraints for infrastructure providers. | **Strict Provider Pinning:** Lock provider versions in `versions.tf` (`~> 3.0.1`) and rigorously test release candidates in isolated staging. |
| **Monolithic Definitions:** Hardcoding VM hardware flags repeatedly across multiple resource blocks. | **DRY Reusable Modules:** Encapsulate hypervisor edge-case workarounds inside centralized compute modules. |
