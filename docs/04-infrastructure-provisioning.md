# Infrastructure as Code (Terraform)

**Goal:** Provision the "Two-Layer" architecture (Production Containers + KTHW VMs) using Code.

## 1. The Technology Stack
* **Orchestrator:** Terraform

## 2. Challenges & Engineering Solutions (The "DevOps Reality")

### Challenge A: Proxmox 9 vs. Provider Permissions
**Issue:** Proxmox VE 9 removed the \`VM.Monitor\` permission. The default Terraform provider checked for this permission and failed, causing a "Permission Denied" error even for the root user.
**Solution:**
* Upgraded Provider to the \`3.x\` Release Candidate series.
* Implemented the flag \`pm_minimum_permission_check = false\` to bypass legacy checks.

### Challenge B: The "Bleeding Edge" Crash
**Issue:** Provider version \`3.0.2-rc05\` introduced a panic (crash) when reading Cloud-Init configurations, making the plan fail.
**Solution:**
* Pinned the provider version to **\`3.0.2-rc04\`**.
* This specific version sits in the "Goldilocks Zone": it supports the Proxmox 9 permission bypass *without* containing the crash bug found in later RCs.

### Challenge C: Syntax Migration
**Issue:** Modern provider versions deprecated the root-level \`cores\` argument.
**Solution:** Refactored all VM resources to use the structured \`cpu { cores = x }\` block.

## 3. Resource Inventory
Successfully provisioned 5 Nodes:

| Name | Type | Zone | IP | Role |
| :--- | :--- | :--- | :--- | :--- |
| **gateway** | LXC | A (Prod) | \`192.168.0.10\` | Traefik Ingress / Reverse Proxy |
| **jumpbox** | VM | B (Lab) | \`192.168.0.20\` | Kubernetes Admin Node |
| **server** | VM | B (Lab) | \`192.168.0.21\` | Kubernetes Control Plane |
| **node-0** | VM | B (Lab) | \`192.168.0.22\` | Worker Node |
| **node-1** | VM | B (Lab) | \`192.168.0.23\` | Worker Node |

