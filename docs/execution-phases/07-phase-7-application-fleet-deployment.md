# Phase 7 Execution Guide: Production Application Fleet Deployment, Storage Tiering & ChatOps Verification

> **Phase Identifier:** PHASE-07  
> **Target Components:** `kubernetes/apps/`, CloudNativePG HA, Hardened n8n, 2 Public Websites, Sovereign Media Stack (1TB HDD), OCI Uptime Kuma, Slack ChatOps  
> **Status:** Completed  
> **Prerequisites:** Phase 6 Completed ([06-phase-6-gitops-bootstrap-sops.md](file:///home/vsc/devlopment/myGH/homelab-ops/process/execution-phases/06-phase-6-gitops-bootstrap-sops.md)) (Flux CD v2 and SOPS operational)

---

## 1. Executive Summary & Objective

Phase 7 is the culminating stage of the homelab modernization. With hardware consolidated, cloud costs eliminated, GitOps bootstrapped, and storage partitioned, we deploy the full production fleet of **9 containerized workloads and 2 public websites** onto `k3s-prod`.

At the completion of Phase 7:
1. **Core Database & Automation:** **CloudNativePG (CNPG)** provides high-availability PostgreSQL with automated continuous WAL archiving, backing a **hardened, non-root n8n** engine.
2. **Public Presence:** **Preiya's Coaching Portfolio** (`preiya.vijaysingh.cloud`) and the **Homelab Documentation Portal** (`docs.vijaysingh.cloud`) are live with sub-15ms edge latency.
3. **Sovereign Media & Documents:** **Paperless-ngx** (OCR archives), **BookOrbit** (multi-user reading platform with sync), and **Audiobookshelf** operate on the 1TB SATA HDD cold tier.
4. **Productivity:** **Homepage Dashboard**, **Miniflux RSS**, **Linkding**, and **Wger** run with Cloudflare Zero Trust SSO protection.
5. **Observability & ChatOps:** In-cluster Prometheus/Grafana and out-of-band **Uptime Kuma** on OCI Mumbai deliver automated notifications to 5 dedicated Slack channels.

---

## 2. The "Why": Architectural Rationale & Workload Hardening

### A. Neutralizing the n8n "God Pod" (ADR-009)
The previous n8n deployment was a severe security liability: it ran with `hostNetwork: true`, ran as root in initContainers, and mounted private SSH keys to execute root commands on the bare-metal Proxmox hypervisor. 
- **The Remediation:** n8n is strictly isolated in its own Kubernetes namespace with non-root UID 1000, dropped Linux capabilities, pure cluster-internal networking, and all host SSH keys purged. Any infrastructure remediation must communicate via fine-grained, authenticated REST API tokens or event webhooks.

### B. Enterprise Database Resilience (ADR-010)
Replacing the single standalone PostgreSQL container with **CloudNativePG** provides:
- Continuous streaming WAL archiving to MinIO/S3 on the 1TB HDD for **Point-in-Time Recovery (PITR)**.
- Automated failover, self-healing, and zero-downtime rolling database upgrades.
- RPO drops from 24 hours to **<15 minutes**.

### C. Physical Storage Tiering (ADR-013)
- **Hot Tier (256GB NVMe):** Fast transactional I/O for etcd, K3s state, and PostgreSQL active tables.
- **Cold Tier (1TB SATA HDD):** Unstructured bulk files (scanned PDFs, eBooks, audiobooks, and backup snapshots) mounted to `/mnt/hdd/` via PersistentVolumes. This prevents large media files from choking the SSD.

---

## 3. The "What": Application Fleet Architecture Matrix

| Application | Namespace | Public / Private Ingress | Storage Tier | Role & Value |
| :--- | :--- | :--- | :--- | :--- |
| **CloudNativePG** | `database` | ClusterInternal | NVMe (Hot) + HDD (WAL) | Declarative HA PostgreSQL cluster for n8n, Miniflux, and Paperless |
| **n8n (Hardened)** | `automation` | `hooks.vijaysingh.cloud` | NVMe | Central automation hub piping RSS digests and alerts to Slack |
| **Preiya's Portfolio** | `web` | `preiya.vijaysingh.cloud` | NVMe (Static) | Sister's professional coaching website with global CDN edge caching |
| **Homelab Docs** | `web` | `docs.vijaysingh.cloud` | NVMe (Astro) | High-speed architecture showcase with interactive Mermaid diagrams |
| **Homepage** | `portal` | `dash.vijaysingh.cloud` (SSO) | NVMe | Central service directory with live K8s, Proxmox, and resource widgets |
| **BookOrbit** | `media` | `books.vijaysingh.cloud` (SSO) | 1TB HDD (`/mnt/hdd/books`) | Multi-user eBook, PDF, and comic library with reading progress sync |
| **Paperless-ngx** | `documents` | `docs-ocr.vijaysingh.cloud` (SSO) | 1TB HDD (`/mnt/hdd/paperless`) | OCR document scanning, tagging, and searchable PDF archive |
| **Audiobookshelf** | `media` | `audio.vijaysingh.cloud` (SSO) | 1TB HDD (`/mnt/hdd/media`) | Streaming server for audiobooks and podcasts |
| **Miniflux** | `productivity`| `rss.vijaysingh.cloud` (SSO) | NVMe | Lightweight Go RSS reader with AI-curated digest integration |
| **Linkding** | `productivity`| `links.vijaysingh.cloud` (SSO) | NVMe | Minimalist, searchable bookmark manager |
| **Wger / Ryot** | `health` | `health.vijaysingh.cloud` (SSO) | NVMe | Workout, calorie, and meal planning tracker |
| **Uptime Kuma** | *(OCI Mumbai)*| `status.vijaysingh.cloud` | OCI Free VM | Out-of-band health probes dispatching alerts to Slack `#homelab-alerts` |

---

## 4. The "How": Step-by-Step Technical Execution

### Step 7.1: Deploy CloudNativePG HA Operator & Database Cluster
Create [kubernetes/platform/postgres-operator/cluster.yaml](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/postgres-operator/cluster.yaml):

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-ha
  namespace: database
spec:
  instances: 2
  primaryUpdateStrategy: unsupervised
  storage:
    size: 20Gi
    storageClass: local-path # NVMe Hot Tier
  backup:
    barmanObjectStore:
      destinationPath: s3://postgres-backups/
      endpointURL: http://minio.database.svc.cluster.local:9000
      s3Credentials:
        accessKeyId:
          name: minio-creds
          key: ACCESS_KEY
        secretAccessKey:
          name: minio-creds
          key: SECRET_KEY
      wal:
        compression: gzip
```

### Step 7.2: Deploy Hardened n8n Workflow Engine
Create [kubernetes/apps/n8n/deployment.yaml](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/apps/n8n/deployment.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: automation
spec:
  replicas: 1
  template:
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: n8n
        image: n8nio/n8n:latest
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        env:
        - name: DB_TYPE
          value: postgresdb
        - name: DB_POSTGRESDB_HOST
          value: postgres-ha-rw.database.svc.cluster.local
        - name: N8N_ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: n8n-secrets
              key: encryption-key
        resources:
          limits:
            memory: 1024Mi
            cpu: 1000m
          requests:
            memory: 384Mi
            cpu: 100m
```

### Step 7.3: Deploy Public Websites
1. **Website 1 (Preiya's Portfolio):** In `kubernetes/apps/website-preiya/`, deploy the static Nginx Alpine container mapped via Traefik Ingress to host `preiya.vijaysingh.cloud`.
2. **Website 2 (Homelab Docs):** In `kubernetes/apps/website-docs/`, deploy the Astro + Starlight container mapped to host `docs.vijaysingh.cloud`.

### Step 7.4: Configure Sovereign Storage Class & Deploy Media Stack
1. Create a local persistent storage class pointing to `/mnt/hdd/` on the node:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hdd-books
spec:
  capacity:
    storage: 400Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/hdd/books
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hdd-paperless
spec:
  capacity:
    storage: 200Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/hdd/paperless
```
2. Deploy **BookOrbit** with its library volume claim bound to `pv-hdd-books`.
3. Deploy **Paperless-ngx** with its document storage claim bound to `pv-hdd-paperless`.

### Step 7.5: Deploy Uptime Kuma on OCI Always Free & Configure Slack
1. **Provision OCI Mumbai Always Free Compute Instance via Terraform:**
   ```bash
   cd infrastructure/oci
   cp terraform.tfvars.example terraform.tfvars # Fill in OCI OCIDs and API key path
   terraform init -backend-config=backend.conf
   terraform apply
   ```
2. **Deploy Uptime Kuma & Docker Stack via Ansible:**
   ```bash
   cd ../../configuration
   # Update inventory/hosts.yml with the provisioned OCI instance IP
   ansible-playbook -i inventory/hosts.yml playbooks/deploy_uptime_kuma.yml
   ```
3. In the Uptime Kuma web interface (`http://<OCI_IP>:3001` or `https://status.vijaysingh.cloud`), add monitors for:
   - `https://docs.vijaysingh.cloud`
   - `https://hooks.vijaysingh.cloud`
   - `https://hub.vijaysingh.cloud`
   - `https://docs-ocr.vijaysingh.cloud`
   - `https://rss.vijaysingh.cloud`
   - Ping monitor to home router via Tailscale IP.
4. Configure Slack Incoming Webhook notifications targeting `#homelab-alerts`.


### Step 7.6: Centralize Slack ChatOps Routing
Configure n8n and Prometheus Alertmanager to route alerts to dedicated Slack channels:

```
Slack Workspace Integrations:
├── #daily-briefing    <-- Miniflux curated AI RSS news digest (n8n daily at 08:00)
├── #documents         <-- Paperless-ngx OCR completion & invoice filing notifications
├── #homelab-alerts    <-- Uptime Kuma out-of-band availability alerts
├── #infra-monitoring  <-- Prometheus node memory, IOPS, and disk threshold alerts
└── #deployments       <-- Flux CD v2 GitOps reconciliation and image update events
```

---

## 5. Verification & Validation Commands

### Check 1: Audit All Cluster Pods
```bash
kubectl get pods -A
```
*Expected Output:* All pods in `automation`, `database`, `web`, `media`, `portal`, `documents`, and `monitoring` report status `Running` with zero restarts.

### Check 2: Verify Public Endpoint SSL and TTFB
```bash
curl -I https://preiya.vijaysingh.cloud
curl -I https://docs.vijaysingh.cloud
curl -I https://hooks.vijaysingh.cloud
```
*Expected Output:* `HTTP/2 200 OK`, `server: cloudflare`, SSL certificate valid, sub-50ms response.

### Check 3: Verify Multi-User Account Creation in BookOrbit
Access `https://books.vijaysingh.cloud`, log in to the Admin workspace, create a secondary test user, and verify independent reading progress tracking.

### Check 4: Test Out-of-Band Slack Alerting
Temporarily pause the `cloudflared` pod:
```bash
kubectl -n cloudflared scale deployment cloudflared --replicas=0
```
*Expected Output:* Within 60 seconds, Uptime Kuma on OCI Mumbai posts an outage notification to Slack `#homelab-alerts`. Scale back up:
```bash
kubectl -n cloudflared scale deployment cloudflared --replicas=1
```
*Expected Output:* Uptime Kuma posts a "Service Restored" notification to Slack.

---

## 6. Failure Modes & Rollback Strategy

| Failure Mode | Root Cause | Immediate Remediation |
| :--- | :--- | :--- |
| Paperless OCR worker causes high CPU contention | Unrestricted OCR worker threads | Set `PAPERLESS_OCR_THREADS=1` and `PAPERLESS_OCR_MAX_IMAGE_PIXELS` in deployment env |
| PostgreSQL WAL archiving fails | In-cluster MinIO endpoint down | Verify MinIO service in `database` namespace; check PVC disk space on HDD |
| Ingress 404 on public website | Traefik IngressRoute missing matching host header | Inspect Traefik dashboard or check `IngressRoute` host definition |

- **Rollback Procedure:** With GitOps active, any malfunctioning application overlay can be reverted or scaled to zero by committing a `git revert` to the `main` branch. Flux CD will reconcile the cluster back to the previous healthy commit in <60 seconds.
