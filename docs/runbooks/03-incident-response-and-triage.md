# Runbook: Incident Response, Diagnostics & Triage Playbook

| Operational Parameter | Production Specification |
| :--- | :--- |
| **Document Classification** | Site Reliability Engineering (SRE) Emergency Triage Playbook |
| **Target Infrastructure** | K3s Kubernetes Cluster, Cloudflare Zero Trust, CloudNativePG, Tailscale |
| **Escalation Notification** | Slack Multi-Channel ChatOps (`#homelab-alerts`, `#deployments`) |
| **Primary Toolchains** | `kubectl`, `flux`, `curl`, `crictl`, `journalctl`, `systemctl` |
| **Relevant Decisions** | [ADR-006](../adr/README.md#adr-006), [ADR-009](../adr/README.md#adr-009), [ADR-010](../adr/README.md#adr-010), [ADR-011](../adr/README.md#adr-011) |

---

## 1. Incident Severity Classification Matrix

| Severity Level | Definition & Criteria | Target Response | Target Resolution | Escalation Channel |
| :--- | :--- | :--- | :--- | :--- |
| **P0 — Critical** | Total platform outage, hardware death, database corruption, or public DNS severance. | **< 5 Minutes** | **< 45 Minutes** | Slack `#homelab-alerts` + SMS/Call |
| **P1 — High** | Public ingress down (`cloudflared` offline), database running on single standby without replication. | **< 15 Minutes** | **< 2 Hours** | Slack `#homelab-alerts` |
| **P2 — Medium** | Single non-critical application degraded (e.g. Miniflux, BookOrbit) while core ingress remains online. | **< 1 Hour** | **< 8 Hours** | Slack `#homelab-alerts` |
| **P3 — Low** | Telemetry ingestion anomaly, non-blocking certificate renewal warning, or scheduled backup delay. | **Next Business Day**| **< 48 Hours** | Slack `#deployments` |

---

## 2. First 5 Minutes: Rapid Diagnostic Protocol

When an incident alert fires from Uptime Kuma or kwatch:

```bash
# Step 1: Check Out-of-Band External Status (from Laptop)
curl -sI https://docs.vijaysingh.cloud | head -n 5

# Step 2: Test Direct Hypervisor Reachability over Tailscale Mesh
curl -k -s -o /dev/null -w "%{http_code}\n" https://100.108.178.93:8006/api2/json

# Step 3: Run Full Cluster Health Sweep
ssh devops@192.168.1.30 "kubectl get nodes && kubectl get pods -A | grep -v -E 'Running|Completed'"
```

- **If Step 1 fails but Step 2 succeeds:** Ingress connector (`cloudflared`) or Traefik is down. Proceed to **Playbook 2**.
- **If Step 1 and Step 2 both fail:** Home power failure or residential ISP broadband drop. Verify physical hardware status.
- **If Step 3 shows unhealthy pods:** Proceed to **Playbook 1** or **Playbook 3**.

---

## 3. Diagnostic & Remediation Playbooks

### Playbook 1: Pod in `CrashLoopBackOff` or `OOMKilled`

1. Inspect pod status and termination reason:
```bash
kubectl describe pod -n <NAMESPACE> <POD_NAME> | grep -E "State:|Reason:|Exit Code:"
```

2. If `Reason: OOMKilled` (Exit Code 137):
- The workload exceeded its memory limit.
- Edit the application manifest in `kubernetes/apps/<APP_NAME>/deployment.yaml` to increase `resources.limits.memory`.
- Commit to Git and reconcile via Flux: `git commit -am "fix: increase memory limit" && git push && flux reconcile kustomization apps --with-source`.

3. If application crash (Exit Code 1):
```bash
# Stream previous crashed container logs
kubectl logs -n <NAMESPACE> <POD_NAME> --previous --tail=100
```

---

### Playbook 2: Cloudflare Zero Trust Ingress Severed (HTTP 530 / 502)

1. Check the `cloudflared` connector pod status:
```bash
kubectl -n platform get pods -l app.kubernetes.io/name=cloudflared
```

2. Inspect connector logs for connection errors:
```bash
kubectl -n platform logs deployment/cloudflared --tail=50
```

3. **Common Cause A: QUIC Connection Failure (UDP 7844 blocked by ISP):**
- Update deployment to force TCP fallback:
- Add args: `- --protocol` and `- http2` to container spec.
- Re-apply manifest.

4. **Common Cause B: Bad Gateway (HTTP 502):**
- Traefik Ingress controller service is unreachable.
- Verify Traefik: `kubectl -n kube-system get pods -l app.kubernetes.io/name=traefik`.

---

### Playbook 3: CloudNativePG Database Failover & Replication Split-Brain

1. Check database cluster health and primary role:
```bash
kubectl get cluster -n database postgres-ha
kubectl describe cluster -n database postgres-ha | grep -A 10 "Instances status"
```

2. If primary instance has crashed:
- CloudNativePG performs automatic promotion of the standby replica within 10 seconds.
- Verify that `postgres-ha-rw` service endpoints point to the promoted replica:
```bash
kubectl get endpoints -n database postgres-ha-rw
```

3. If standby replica fails to synchronize:
```bash
# Force pod restart of the out-of-sync standby
kubectl delete pod -n database postgres-ha-2
# The operator will automatically rebuild the replica from the primary WAL stream.
```

---

### Playbook 4: In-Memory SOPS Secret Decryption Failure

*Symptom:* Flux reports `failed to decrypt secret: no matching keys found`.

1. Verify that the `sops-age` secret exists in `flux-system`:
```bash
kubectl -n flux-system get secret sops-age
```

2. Verify that the public key declared in `.sops.yaml` matches the private key loaded in the cluster:
```bash
# Inspect in-cluster Age public key
kubectl -n flux-system get secret sops-age -o jsonpath="{.data['age\.agekey']}" | base64 -d | age-keygen -y
# Compare output against the 'age:' string in .sops.yaml
```

3. If mismatched, re-inject the correct Age private key:
```bash
cat ~/.config/sops/age/keys.txt | kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=/dev/stdin \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

### Playbook 5: Secondary SATA Mechanical Storage Unmounted (`/mnt/hdd`)

*Symptom:* Workloads mounting cold tier volumes (Paperless, BookOrbit) enter `ContainerCreating` with `MountVolume.SetUp failed`.

1. SSH into the production node:
```bash
ssh devops@192.168.1.30
```

2. Check block device status:
```bash
lsblk
```

3. Re-mount filesystems defined in `/etc/fstab`:
```bash
sudo mount -a
df -h /mnt/hdd
```

4. If drive is missing from `lsblk`, verify VirtIO SCSI attachment in Proxmox hypervisor (`qm config 500`).

---

## 4. Post-Incident Review (PIR) Protocol

Following the resolution of any P0 or P1 incident:
1. Document root cause, timeline of events, and time-to-recovery (TTO/TTR).
2. Establish whether existing health probes detected the failure in <60 seconds.
3. Commit permanent remediation to Git (preventing recurrence through code or alerts).
4. Update incident archive in `docs/archive/post-mortems/`.
