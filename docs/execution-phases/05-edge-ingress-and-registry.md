# Phase 5: Cloudflare Edge Ingress & Container Registry Decoupling

| Milestone Attribute | Engineering Specification |
| :--- | :--- |
| **Phase Scope** | Edge Ingress Routing, CGNAT Traversal & Container Registry Migration |
| **Target Infrastructure** | Cloudflare Edge Network, `k3s-prod` (`cloudflared`), GitHub Container Registry |
| **Primary Code Paths** | [`kubernetes/platform/cloudflared/`](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/cloudflared/), [`.github/workflows/`](file:///home/vsc/devlopment/myGH/homelab-ops/.github/workflows/) |
| **Relevant Decisions** | [ADR-006](../adr/README.md#adr-006), [ADR-008](../adr/README.md#adr-008) |
| **Operational Status** | Production Verified (Platform v3.0.0) |

---

## 1. Executive Summary & Objective

Phase 5 achieves three fundamental networking and operational milestones:
1. **Sub-15ms Ingress Latency:** Deploys **Cloudflare Zero Trust Tunnels (`cloudflared`)** inside `k3s-prod`, terminating traffic at Indian Anycast edge data centers (Mumbai, Delhi, Chennai) with zero open home router ports and enterprise DDoS mitigation.
2. **GCP Gateway Detachment:** Retires legacy WireGuard gateway routing from the Google Cloud Platform (GCP) Compute Engine instance (`us-east1`). The instance is unencumbered and preserved for future multi-cloud hybrid compute tasks.
3. **Container Registry Decoupling:** Migrates container image storage and automated CI/CD build pipelines to **GitHub Container Registry (`ghcr.io`)**, tightly coupling image lifecycle with Git repository commits.

---

## 2. Engineering Rationale: Latency Physics & Security Hardening

### A. Eliminating the 500ms Cross-Atlantic Routing
Under the legacy architecture, domestic requests traveled across the Atlantic Ocean twice:

$$\text{Visitor (India)} \xrightarrow{220\text{ms}} \text{GCP us-east1 (USA)} \xrightarrow[\text{WireGuard}]{220\text{ms}} \text{Home Proxmox} \xrightarrow{220\text{ms}} \text{GCP} \xrightarrow{220\text{ms}} \text{Visitor}$$

Compound round-trip latency exceeded **450ms–500ms per request**, making interactive Single Page Applications (like n8n canvas and modern dashboards) extremely sluggish.

### B. The Cloudflare Edge Advantage
With Cloudflare Tunnels:

- `cloudflared` initiates secure, outbound-only QUIC/HTTPS streams to Cloudflare edge nodes in Mumbai, Delhi, and Chennai.
- Public requests to `docs.vijaysingh.cloud` terminate at the nearest Indian edge point-of-presence in **<15ms**.
- The residential router firewall remains 100% closed: no inbound ports (80/443/51820) are forwarded, completely shielding the residential IP address.

---

## 3. Global Network Ingress Topology

```
Ingress Flow:
[ Public User / Recruiter ]
        │ HTTPS (<15ms)
        ▼
[ Cloudflare Anycast Edge (Mumbai / Delhi / Chennai) ]
        │ WAF, DDoS Shield, Edge TLS Termination
        │
        │ Encrypted Outbound QUIC Stream (Port 7844 / 443)
        ▼
[ cloudflared Pod (k3s-prod: namespace platform) ]
        │ HTTP Cluster-Internal Routing
        ▼
[ Traefik Ingress Controller (kube-system: Port 80) ]
        │ Path & Host Header Matching
        ├── docs.vijaysingh.cloud  ──► Homelab Docs Portal
        ├── hooks.vijaysingh.cloud ──► n8n Automation Engine
        └── dash.vijaysingh.cloud  ──► Homepage Dashboard (Cloudflare SSO)
```

![Global Multi-Cloud & Network Ingress Topology](../../images/v.3.0.0/global-network-topology.png)

---

## 4. Technical Execution Details

### 1. Deploying `cloudflared` to `k3s-prod`
The tunnel connector was deployed inside the cluster via [kubernetes/platform/cloudflared/cloudflared.yaml](file:///home/vsc/devlopment/myGH/homelab-ops/kubernetes/platform/cloudflared/cloudflared.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: platform
  labels:
    app.kubernetes.io/name: cloudflared
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: cloudflared
  template:
    metadata:
      labels:
        app.kubernetes.io/name: cloudflared
    spec:
      containers:
      - name: cloudflared
        image: cloudflare/cloudflared:latest
        args:
        - tunnel
        - --no-autoupdate
        - run
        - --token
        - $(TUNNEL_TOKEN)
        env:
        - name: TUNNEL_TOKEN
          valueFrom:
            secretKeyRef:
              name: cloudflared-tunnel-token
              key: token
        resources:
          limits:
            cpu: 300m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
```

### 2. Ingress Route Mapping
Inside the Cloudflare Zero Trust Dashboard, public hostnames were routed to the in-cluster Traefik service:

- `docs.vijaysingh.cloud` $\to$ `http://traefik.kube-system.svc.cluster.local:80`
- `hooks.vijaysingh.cloud` $\to$ `http://traefik.kube-system.svc.cluster.local:80`
- `dash.vijaysingh.cloud` $\to$ `http://traefik.kube-system.svc.cluster.local:80` (enforcing Google SSO via Cloudflare Access)

### 3. GCP Gateway Detachment
- Deactivated WireGuard gateway routing on the GCP VM.
- Cleaned public DNS records pointing to the legacy GCP static IP.
- Preserved the GCP Compute instance for future off-site hybrid computing tasks.

### 4. Container Registry Migration to `ghcr.io`
Configured GitHub Actions workflows to build and push container images to GitHub Container Registry:

```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Build and Push Custom Image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: ghcr.io/vsingh55/homelab-docs:latest
```

---

## 5. Verification & Quality Assertions

### 1. Tunnel Connector Health
```bash
kubectl -n platform get pods -l app.kubernetes.io/name=cloudflared
kubectl -n platform logs deployment/cloudflared | grep "Registered tunnel connection"
# Output: Pod is Running; confirms 4 active dual-stream connections to Indian edge nodes.
```

### 2. Edge Response Latency Audit
```bash
curl -w "DNS: %{time_namelookup}s | Connect: %{time_connect}s | TTFB: %{time_starttransfer}s | Total: %{time_total}s\n" \
  -o /dev/null -s https://docs.vijaysingh.cloud
# Output: Total latency is consistently <0.050s (<50ms end-to-end page delivery).
```

### 3. Inbound Firewall Verification
Verified via external port scan that home residential router has zero open inbound ports (80, 443, 51820 are closed/stealthed).

---

## 6. Exit Gate & Phase Transition

With edge Anycast routing established and container registry decoupled, the platform proceeded to **[Phase 6: Declarative GitOps Bootstrapping & In-Git Secrets](06-gitops-bootstrap-sops.md)**.
