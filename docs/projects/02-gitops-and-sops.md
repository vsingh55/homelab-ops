# Case Study: Declarative GitOps Continuous Delivery & In-Git Secrets

| Engineering Dimension | Production Specification |
| :--- | :--- |
| **Architecture Pattern** | Pull-Based GitOps Continuous Delivery & Asymmetric Secret Encryption |
| **Core Technologies** | Flux CD v2, Kustomize, Mozilla SOPS, Age Cryptography, GitHub |
| **Primary Code Paths** | [`kubernetes/bootstrap/`](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/bootstrap/), [`kubernetes/platform/`](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/), [`.sops.yaml`](file:///home/vsc/devlopment/myGH/homelab-ops/.sops.yaml) |
| **Relevant Decisions** | [ADR-007](../adr/README.md#adr-007), [ADR-014](../adr/README.md#adr-014) |
| **Operational Status** | Production Verified (100% Declarative, Zero Drift, In-Memory Decryption) |

---

## 1. Executive Summary

Imperative cluster deployments—relying on manual `kubectl apply` commands executed from local operator workstations—invariably introduce configuration drift, untracked modifications, and severe security liabilities. 

This project transformed the entire Kubernetes platform into an automated, pull-based **GitOps Continuous Delivery Engine** powered by **Flux CD v2**. To maintain bank-grade credential security without the memory footprint of an external secret vault cluster, all sensitive tokens and database passwords are encrypted directly inside Git using **Mozilla SOPS and Age asymmetric cryptography**. Secrets are decrypted strictly in-memory by the Flux controller, ensuring zero plaintext exposure across public GitHub repositories and physical storage media.

---

## 2. The Problem: Configuration Drift & Secret Management

1. **Deployment Drift & Unrepeatable State:** When operators or scripts apply ad-hoc changes via `kubectl apply`, live cluster state diverges from Git repository manifests. When outages occur or nodes must be rebuilt, recreating exact state from scratch becomes nearly impossible.
2. **Boot-Order Race Conditions:** Kubernetes workloads frequently fail on startup if platform primitives (Custom Resource Definitions, storage classes, database operators) are not completely healthy before application manifests are scheduled.
3. **The Secret Management Dilemma:** Storing plaintext credentials in Git commits is a catastrophic security risk. However, hosting an enterprise HashiCorp Vault cluster on a 16GB host consumes ~1.5GB of RAM, requires complex auto-unseal mechanics, and adds substantial operational friction for a lean engineering team.

---

## 3. GitOps Delivery & Secret Decryption Pipeline

```
Pipeline Lifecycle:
[ Engineer Workstation ]
        │ • Edits Kubernetes Manifests
        │ • Encrypts Secrets In-Place: sops --encrypt my-secret.yaml
        ▼
[ GitHub Repository: homelab-ops (origin/main) ]
        │ • Versioned Kustomize Overlays
        │ • Encrypted Secrets (*.enc.yaml)
        │ • Commit History as Single Source of Truth
        ▼
[ Flux CD v2 Controller Loop (k3s-prod: ~120MB RAM) ]
        ├── Stage 1: source-controller pulls commit via webhook / poll
        ├── Stage 2: kustomize-controller reads in-cluster Secret (sops-age)
        ├── Stage 3: Decrypts *.enc.yaml dynamically into RAM
        └── Stage 4: Applies desired state with deterministic dependsOn ordering
        ▼
[ Native Kubernetes Workloads (CloudNativePG, n8n, Media Stack) ]
```

![Declarative GitOps & Secret Lifecycle Pipeline](../images/v.3.0.0/gitops-pipeline.png)

---

## 4. Key Architectural Implementations

### 1. In-Git Asymmetric Encryption with Mozilla SOPS & Age
Rather than storing whole encrypted blobs or relying on symmetric passwords:

- Developers encrypt secrets using the platform's public Age key (`age1...`) defined in [.sops.yaml](file:///home/vsc/devlopment/myGH/homelab-ops/.sops.yaml).
- SOPS encrypts **strictly the YAML values**, leaving object names, keys, and metadata in plain text for transparent code reviews and Git diff inspections.
- The private Age secret key (`AGE-SECRET-KEY-...`) is injected into the `flux-system` namespace once during initial bootstrap and never leaves cluster memory.

```yaml
# Repository SOPS Creation Rules (.sops.yaml)
creation_rules:
  - path_regex: kubernetes/.*\.enc\.yaml$
    encrypted_regex: "^(data|stringData)$"
    age: "age14g9mflspwt7n695jhe36873528t383g2v5u5c6y86p4mznv3g9ys4r6q0v"
```

### 2. Deterministic Stage Chaining (`dependsOn`)
To prevent startup race conditions, the root Flux configuration partitions delivery into structured dependency phases:

```yaml
# Root Application Delivery (kubernetes/bootstrap/apps.yaml)
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./kubernetes/apps
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  # Enforce platform readiness before application scheduling
  dependsOn:
    - name: platform
  # Enable in-memory SOPS decryption
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Workloads in `apps` (such as n8n or Paperless) are held in pending state until the `platform` Kustomization (CloudNativePG operator, storage classes, `cloudflared`) reports healthy.

### 3. Continuous Self-Healing & Drift Neutralization
The Flux control loop continuously compares live cluster state against `origin/main` every 10 minutes (or immediately via GitHub push webhooks):

- If an unauthorized manual change is introduced via `kubectl`, Flux immediately overrides the drift and restores the Git-defined configuration.
- If a manifest is deleted from Git, Flux automatically prunes the corresponding Kubernetes resource from the cluster (`prune: true`).

---

## 5. Verification & Operational Health

### 1. Flux Controller Health Audit
```bash
flux check
```
*Actual Result:*
```
► checking prerequisites
✔ Kubernetes 1.30.0+k3s1 >=1.28.0-0
► checking controllers
✔ all desired controllers are healthy (source-controller, kustomize-controller, helm-controller)
✔ crds.kustomize.toolkit.fluxcd.io/v1 is up to date
```

### 2. Kustomization Reconciliation Status
```bash
flux get kustomizations
```
*Actual Result:*
```
NAME         REVISION            SUSPENDED READY MESSAGE
flux-system  main@sha1:d4ba838   False     True  Applied revision: main@sha1:d4ba838
platform     main@sha1:d4ba838   False     True  Applied revision: main@sha1:d4ba838
apps         main@sha1:d4ba838   False     True  Applied revision: main@sha1:d4ba838
```

### 3. In-Memory Decryption Verification
```bash
# Verify decrypted secret in cluster memory
kubectl get secret -n database postgres-credentials -o jsonpath='{.data.password}' | base64 -d
```
*Actual Result:* Plaintext password returned instantly in cluster memory, while Git repository inspects strictly as ciphertext (`ENC[AES256_GCM...]`).

---

## 6. Quantified Engineering Impact

| Operational Dimension | Imperative Baseline (v2) | GitOps + SOPS (Current) | Engineering Yield |
| :--- | :--- | :--- | :--- |
| **Configuration Drift** | Frequent untracked manual edits | **0% Drift (Continuous Control Loop)** | **Immutable, Self-Healing Operations** |
| **Secret Storage Safety** | Plaintext in memory / Local disk | **Asymmetric In-Git Encryption (Age)** | **Zero Secret Leaks in Git History** |
| **Controller RAM Overhead** | ~800MB–1.2GB (ArgoCD + Redis) | **~120MB (Flux CD v2 Controllers)** | **~85% Memory Savings for Apps** |
| **Startup Race Conditions** | Manual sequencing / Pod crash loops | **Automated `dependsOn` Verification** | **Zero Workload Boot Failures** |
| **Disaster Recovery Velocity** | Hours of manual script execution | **< 15 Minutes (Single Git Bootstrap)** | **Deterministic Point-in-Time Recovery** |
