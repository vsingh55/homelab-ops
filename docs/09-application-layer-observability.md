# 09. Application Layer & Observability

**Goal:** Establish a production-grade Kubernetes application plane with enterprise-standard observability, security controls, and traffic management to enable reliable, auditable workload operations in the homelab environment.

**Scope:** Production Zone (`k3s-prod`)

## 1. The Strategy
With the infrastructure and networking layers stable, we shifted focus to the **Application Plane**. The goal was to establish a production-grade Kubernetes environment for persistent workloads.

## 2. The Stack
We deployed a standard "Cloud Native" stack on the `k3s-prod` node:
* **Ingress Controller:** **Traefik v2**. Acts as the Layer 7 Load Balancer, routing traffic from ports 80/443 to internal services.
* **Observability:** **Kube-Prometheus-Stack**.
    * **Prometheus:** Time-series database for metrics.
    * **Grafana:** Visualization dashboard.
    * **Node-Exporter:** Hardware telemetry (CPU/RAM/Disk).

## 3. Security Implementation
* **Secret Management:** Grafana admin credentials were removed from plain text code and tokenized using **Ansible Vault**.
* **Ingress Routing:** Services are exposed via Traefik `IngressRoutes`, ensuring no direct NodePort exposure for administrative interfaces.

## 4. Challenges & Solutions
* **Issue:** Helm failed to deploy Traefik due to schema validation errors (`got boolean, want object`).
* **Fix:** Updated the `values.yaml` template to match the modern Traefik chart schema (`expose: { default: true }`).
* **Issue:** Missing Grafana Dashboards on restart.
* **Fix:** Implementation of PVC (Persistent Volume Claims) and Rclone Backups.