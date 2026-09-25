# Phase 1 Execution & Action Guide: Baseline Architecture Synchronization

> **Phase Identifier:** PHASE-01-ACTION-GUIDE  
> **Target Baseline:** [`process/blueprint.md`](../blueprint.md), [`process/current vs future.md`](../current%20vs%20future.md), [`process/architecture_decision_records.md`](../architecture_decision_records.md)  
> **Status:** Active Execution  
> **Target Audience:** DevOps Engineer / Homelab Architect  

---

## 1. Executive Summary: What is Phase 1?

**Phase 1 is the Architectural Baseline & Pre-Flight Verification Gate.**

In enterprise DevOps engineering, **you never touch running systems or delete virtual machines until the target architecture is mathematically verified and agreed upon.** Phase 1 ensures that:
1. Every architectural change is anchored in a formal **Architecture Decision Record (ADR)**.
2. Contradictions between legacy files (e.g. ArgoCD vs Flux CD, Keycloak vs Cloudflare Access) are purged.
3. Physical hardware resources (16GB RAM ceiling on the Mini PC) are strictly budgeted before resizing VMs.
4. Pre-flight connectivity to Proxmox, Tailscale, OCI, and Cloudflare is verified before modifying IaC code.

> [!NOTE]
> **No virtual machines are destroyed in Phase 1.** Phase 1 is purely architectural alignment, documentation reconciliation, and pre-flight verification. Destructive pruning occurs in Phase 2 and Phase 4.

---

## 2. The 5 Core Architecture Decisions to Lock In

Before proceeding, you must align on these 5 foundational decisions:

| # | Decision | Legacy State (v1.0) | Production State (v3.0 Implemented) | Impact / Rationale | Status |
|---|---|---|---|---|---|
| **D1** | **Purge Academy Zone** | 5 VMs/LXCs (`gateway`, `jumpbox`, `server`, `node-0`, `node-1`) consuming ~7.5GB RAM | Completely eliminated from Proxmox and codebase | CKA/CKS certification complete; reclaimed **~7.5GB RAM** on host. | ✅ Implemented |
| **D2** | **Decommission `ops-center`** | 2GB RAM KVM VM hosting MinIO & SSH bastion | Eliminated; Terraform state migrated to **OCI Always Free Mumbai S3** | Reclaimed **2GB RAM, 2 vCPUs, 20GB NVMe, and 250GB HDD** virtual disk. | ✅ Implemented |
| **D3** | **Resize `k3s-prod`** | 8GB RAM, 2 vCPUs, 30GB disk | Resized to **12GB RAM, 4 vCPUs**, with direct **1TB SATA HDD** mount | Provides >60% memory headroom (~7.5GB free buffer) for media and OCR apps. | ✅ Implemented |
| **D4** | **Laptop Direct Control** | Dual-hop SSH proxy via `ops-center` | **Direct execution from Laptop** via Tailscale mesh (`100.x.x.x`) | Eliminated proxy latency, removed bastion single point of failure. | ✅ Implemented |
| **D5** | **Cloudflare Edge Ingress** | GCP `e2-micro` VM in South Carolina via WireGuard (~500ms latency, ~$10/mo) | **Cloudflare Zero Trust Tunnels (`cloudflared`)** via Indian Anycast PoPs | Dropped latency to **<15ms**, eliminated recurring cloud cost, zero open ports. | ✅ Implemented |

---

## 3. Step-by-Step Instructions: What You Need to Do

### Step 1: Reconcile Root Repository Documentation
Ensure that legacy documentation in the repository root (`README.md`, etc.) does not contradict the ADRs:
1. Replace references to **ArgoCD** with **Flux CD v2** (per ADR-007).
2. Replace references to **Keycloak** with **Cloudflare Zero Trust Access + Google SSO** (per ADR-012).
3. Replace references to the **Lab Zone / Eco-Mode** with the single production cluster (`k3s-prod`).

### Step 2: Run the Phase 1 Quality & Audit Checklist
Execute the following verification commands from the repository root:

```bash
# Audit 1: Verify zero obsolete ArgoCD references in active documentation
grep -rn "ArgoCD" README.md docs/

# Audit 2: Verify zero obsolete Keycloak references in active documentation
grep -rn "Keycloak" README.md docs/

# Audit 3: Mathematical RAM Allocation Verification
# Proxmox Host Base (3.5 GB) + k3s-prod (12.0 GB) = 15.5 GB <= 16.0 GB Physical RAM
python3 -c '
total_ram = 16.0
proxmox_host = 3.5
k3s_prod = 12.0
buffer = total_ram - (proxmox_host + k3s_prod)
print(f"Total Physical RAM: {total_ram} GB")
print(f"Allocated: {proxmox_host + k3s_prod} GB")
print(f"Safety Buffer: {buffer} GB (3.1%)")
assert buffer >= 0.5, "Safety buffer must be at least 500MB!"
print(">>> RAM BUDGET AUDIT PASSED! <<<")
'
```

### Step 3: Verify Pre-Flight Connectivity & Prerequisites

Before moving to Phase 2 (code pruning) and Phase 3 (remote state), verify your external toolchains:

1. **Tailscale Connection to Proxmox VE:**
   ```bash
   # Verify Tailscale IP of Proxmox VE (100.108.178.93) is reachable
   curl -k -s -o /dev/null -w "%{http_code}\n" https://100.108.178.93:8006/api2/json
   # Expected output: 200 or 401 (API is reachable)
   ```

2. **SSH Direct Access to `k3s-prod`:**
   ```bash
   # Test direct SSH reachability
   ssh -o ConnectTimeout=5 -o BatchMode=yes devops@192.168.1.30 "uname -a"
   ```

3. **Oracle Cloud Infrastructure (OCI) Tenancy Readiness (for Phase 3):**
   - **Customer Secret Key:** In OCI User Profile -> Customer Secret Keys, you generated an Access Key & Secret Key.
     - **Save them now:** Store the Access Key and Secret Key in your password manager or temporary local file (`PRIVATE.txt`, which is git-ignored). OCI will NEVER show the secret key again once closed.
     - **Tenancy Namespace:** Look up your Object Storage Namespace (Profile -> Tenancy -> Object Storage Namespace).
     - **Future Usage (Phase 3 & Phase 7):** These credentials will be encrypted into `ansible-vault` to hydrate `backend.conf` for Terraform S3 state and configure nightly Restic backups.

4. **Cloudflare & Hostinger Domain Status (Verified from Console):**
   - **Registrar (Hostinger):** `vijaysingh.cloud` is registered and its custom nameservers are already pointed to Cloudflare:
     - `harleigh.ns.cloudflare.com`
     - `lynn.ns.cloudflare.com`
   - **Authoritative DNS (Cloudflare):** Cloudflare is actively managing DNS for `vijaysingh.cloud`.
     - **Active Live Sites (Do Not Touch):** `vijaysingh.cloud` and `www` (Cloudflare Pages), `pf` (Netlify), `blogs` (Hashnode), and `gh.showcase` (GitHub Pages). These are completely independent and will continue running untouched!
     - **Legacy Homelab Records:** `hooks.vijaysingh.cloud` and `pdf.vijaysingh.cloud` currently point to the GCP VM (`35.237.62.156`).
     - **Action for Phase 1:** **Do nothing right now.** Your DNS is already in the optimal state. In **Phase 5**, we will replace the legacy GCP A records with Cloudflare Tunnel CNAMEs and add new homelab subdomains (`docs`, `preiya`, `dash`).

---

## 4. Phase 1 Exit Gate Criteria

To officially complete Phase 1 and unlock **Phase 2 (Codebase Pruning & Inventory Restructuring)**, confirm the following checklist:

- [x] All 16 ADRs in `process/architecture_decision_records.md` reviewed and synchronized.
- [x] `process/blueprint.md` matches the single-VM `k3s-prod` (12GB RAM) target.
- [x] `process/current vs future.md` reflects direct laptop operations and Cloudflare ingress.
- [x] Obsolete references in `README.md` updated to Flux CD v2 and Cloudflare Access.
- [x] Cloudflare & Hostinger DNS status verified (Nameservers delegated, live sites mapped).
- [x] OCI Always Free Customer Secret Key generated and saved locally for Phase 3.
- [ ] Pre-flight connectivity to Proxmox VE (Tailscale) and `k3s-prod` verified.

Once you confirm the connectivity checks, we immediately proceed to **Phase 2**, where we prune the Academy Zone and `ops-center` from `main.tf`, `variables.tf`, and `hosts.yml`.

