# Traefik Ingress Controller

| Component | Specification |
| :--- | :--- |
| **Namespace** | `kube-system` |
| **Deployment Mode** | K3s Native Ingress Controller / Helm |
| **Entrypoints** | `web` (Port 80 / NodePort 30080), `websecure` (Port 443 / NodePort 30443) |
| **Service Endpoint** | `traefik.kube-system.svc.cluster.local:80` |
| **Upstream Tunnel** | `cloudflared` ([`kubernetes/platform/cloudflared/`](../cloudflared/)) |
| **Automation Playbook** | [`configuration/playbooks/deploy_traefik.yml`](../../../configuration/playbooks/deploy_traefik.yml) |
| **Ansible Role** | [`configuration/roles/traefik/`](../../../configuration/roles/traefik/) |

---

## Architecture & Role in Zero-Trust Ingress

Traefik serves as the internal Layer-7 reverse proxy and Ingress Controller for all homelab workloads on the `k3s-prod` cluster.

```
[ Public Client / Edge Request ]
               │
               ▼
[ Cloudflare Zero Trust Edge (Anycast) ]
               │
               ▼ Outbound QUIC/HTTPS Tunnel
[ cloudflared Connector (platform) ]
               │
               ▼ http://traefik.kube-system.svc.cluster.local:80
[ Traefik Ingress Controller (kube-system) ]
               │
               ├── docs.vijaysingh.cloud  ──► [ platform: docs ]
               ├── dash.vijaysingh.cloud  ──► [ platform: homepage ]
               ├── hooks.vijaysingh.cloud ──► [ apps: n8n ]
               ├── books.vijaysingh.cloud ──► [ apps: bookorbit ]
               └── ocr.vijaysingh.cloud   ──► [ apps: paperless ]
```

### Ingress Specifications
Workloads across [`kubernetes/platform/`](../) and [`kubernetes/apps/`](../../apps/) bind to Traefik using standard Kubernetes `Ingress` manifests:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: example.vijaysingh.cloud
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```
