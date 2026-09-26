# Phase 6: Declarative GitOps Bootstrapping & In-Git Secret Encryption

| Milestone Attribute | Engineering Specification |
| :--- | :--- |
| **Phase Scope** | Continuous Delivery Control Loop & Asymmetric Secret Encryption |
| **Target Infrastructure** | K3s Kubernetes Cluster (`k3s-prod`), Flux CD v2, Mozilla SOPS |
| **Primary Code Paths** | [`kubernetes/bootstrap/`](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/bootstrap/), [`kubernetes/platform/`](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/), [`.sops.yaml`](file:///home/vsc/devlopment/myGH/homelab-ops/.sops.yaml) |
| **Relevant Decisions** | [ADR-007](../adr/README.md#adr-007), [ADR-014](../adr/README.md#adr-014) |
| **Operational Status** | Production Verified (Platform v3.0.0) |

---

## 1. Executive Summary & Objective

Phase 6 institutes enterprise-grade **GitOps Continuous Delivery** and **Cryptographic In-Git Secrets Management** on `k3s-prod`.

At the completion of this phase:
1. **Flux CD v2** functions as the cluster's autonomous control loop, continuously pulling and reconciling manifests directly from the GitHub repository (`homelab-ops`).
2. Configuration drift is completely eliminated: manual `kubectl apply` interventions are superseded by Git commits.
3. Secrets (database credentials, API tokens, webhook keys) are encrypted in Git via **Mozilla SOPS** using an **Age keypair**, decrypted dynamically in-memory inside K3s.
4. The entire GitOps plane consumes only **~120MB RAM**, preserving maximum memory for production applications.

---

## 2. Engineering Rationale: Lean Tooling Selection

### A. Flux CD v2 vs. ArgoCD (Memory Economics)
While ArgoCD provides an interactive web UI, running its full suite (server, dex, repo-server, application-controller, Redis) consumes **~700MB–1.0GB of RAM**. 

On our 16GB Mini PC running 9 production services:

- **Flux CD v2** uses only **~120MB–150MB RAM** total across its controllers (`source-controller`, `kustomize-controller`, `helm-controller`).
- Flux integrates natively with **Mozilla SOPS** out-of-the-box via Kustomize decryption providers, eliminating third-party sidecars.
- Operating as a pure Kubernetes controller without an exposed web dashboard reduces the cluster attack surface.

### B. Mozilla SOPS + Age vs. HashiCorp Vault
- **HashiCorp Vault** is heavy over-engineering for a single-node platform, consuming >1GB RAM, requiring complex unseal ceremonies, and introducing certificate renewal loops.
- **Mozilla SOPS with Age (`age-keygen`)** encrypts *only* values in YAML manifests, leaving keys, names, and labels in plain text. This allows clean, readable GitHub Pull Request diffs while guaranteeing that no sensitive credentials leak into Git history.

---

## 3. GitOps & Secret Lifecycle Pipeline

```
Reconciliation Architecture:
[ GitHub Repository (origin/main) ]
  ├── .sops.yaml (Age Public Key)
  ├── kubernetes/bootstrap/ (Flux Controllers)
  ├── kubernetes/platform/ (Infra Overlays)
  └── kubernetes/apps/ (Encrypted secrets: *.enc.yaml)
         │
         │ Git Pull Every 10m (or Webhook Trigger)
         ▼
[ Flux CD v2 Engine (flux-system: ~120MB RAM) ]
         │ Reads Secret: sops-age (Age Private Key)
         │ Decrypts secrets in-memory (RAM only)
         ▼
[ Native Kubernetes Secrets & Pods ]
```

![Declarative GitOps & Secret Lifecycle Pipeline](../../images/v.3.0.0/gitops-pipeline.png)

---

## 4. Technical Execution Details

### 1. Generating Master Age Keypair
Generated a dedicated Age keypair on the administrative workstation:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Extract public key (age1...)
grep "public key:" ~/.config/sops/age/keys.txt
```

### 2. Configuring Repository Encryption Rules
Defined [.sops.yaml](file:///home/vsc/devlopment/myGH/homelab-ops/.sops.yaml) at the repository root:

```yaml
creation_rules:
  - path_regex: kubernetes/.*\.enc\.yaml$
    encrypted_regex: "^(data|stringData)$"
    age: "<AGE_PUBLIC_KEY>"
```

### 3. Injecting Age Private Key into Cluster
Injected the private key into the `flux-system` namespace to enable in-memory decryption:

```bash
cat ~/.config/sops/age/keys.txt | kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=/dev/stdin \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. Bootstrapping Flux CD v2 Controller
```bash
flux bootstrap github \
  --owner=vsingh55 \
  --repository=homelab-ops \
  --branch=main \
  --path=kubernetes/bootstrap \
  --personal
```

### 5. Configuring SOPS Decryption in Kustomization
Configured the root Kustomization in `kubernetes/bootstrap/` to decrypt SOPS secrets automatically:

```yaml
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
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

---

## 5. Verification & Quality Assertions

### 1. Flux Controller Health Audit
```bash
flux check
# Output: All checks passed across source-controller, kustomize-controller, and helm-controller.
```

### 2. Kustomization Reconciliation Status
```bash
flux get kustomizations
# Output:
# NAME         REVISION            SUSPENDED READY MESSAGE
# flux-system  main@sha1:2fa158b   False     True  Applied revision: main@sha1:2fa158b
# apps         main@sha1:2fa158b   False     True  Applied revision: main@sha1:2fa158b
```

### 3. In-Memory Decryption Verification
```bash
kubectl get secret -n database postgres-credentials -o jsonpath='{.data.password}' | base64 -d
# Output: Confirms plain-text secret is mounted inside Kubernetes while remaining 100% encrypted in Git.
```

---

## 6. Exit Gate & Phase Transition

With declarative GitOps active and in-git secrets cryptographically protected, the platform advanced to **[Phase 7: Production Application Fleet Deployment & Storage Tiering](07-application-fleet-deployment.md)**.
