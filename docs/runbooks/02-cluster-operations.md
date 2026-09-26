# Runbook: Day-2 Cluster Operations & Maintenance

> **Classification:** Production Operations Runbook 
> **Scope:** Flux CD v2 GitOps, Mozilla SOPS, Secret Management, Cluster Upgrades 

---

## 1. Secret Management with Mozilla SOPS & Age

All sensitive credentials (API tokens, passwords, private keys) are encrypted inside Git using **Mozilla SOPS** and the cluster's **Age** public key.

### Encrypting a New Secret
```bash
# Generate a standard Kubernetes secret manifest
kubectl create secret generic my-secret \
--from-literal=api-key="super-secret-value" \
--dry-run=client -o yaml > kubernetes/apps/my-app/secret.yaml

# Encrypt in place using SOPS (uses .sops.yaml rules)
sops --encrypt --in-place kubernetes/apps/my-app/secret.yaml

# Rename to follow the encrypted secret standard
mv kubernetes/apps/my-app/secret.yaml kubernetes/apps/my-app/secret.enc.yaml
```

### Editing an Existing Encrypted Secret
```bash
# Opens decrypted secret in your default terminal editor ($EDITOR)
# Automatically re-encrypts upon save and exit
sops kubernetes/apps/my-app/secret.enc.yaml
```

---

## 2. GitOps Continuous Delivery Reconciliation

Flux reconciles cluster state automatically every 10 minutes. To force immediate synchronization:

```bash
# 1. Force Git source update
flux reconcile source git flux-system

# 2. Force platform layer synchronization
flux reconcile kustomization platform --with-source

# 3. Force application layer synchronization
flux reconcile kustomization apps --with-source
```

### Inspecting Reconciliation Status
```bash
# View all active Kustomizations and their health
flux get kustomizations

# View recent reconciliation events and error traces
flux events --all-namespaces
```

---

## 3. Node Maintenance & Routine Host Upgrades

### Draining the Node for Maintenance
```bash
# Cordon the node to prevent new pod scheduling
kubectl cordon k3s-prod

# Gracefully drain non-daemonset workloads
kubectl drain k3s-prod --ignore-daemonsets --delete-emptydir-data
```

### Uncordoning Post-Reboot
```bash
# Allow pods to be scheduled again
kubectl uncordon k3s-prod

# Verify all pods return to Running state
kubectl get pods -A
```
