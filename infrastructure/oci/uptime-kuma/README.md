# Out-of-Band Uptime Kuma Deployment (OCI Mumbai)

## Overview
This standalone Docker Compose stack runs out-of-band on the Oracle Cloud Infrastructure (OCI) Always Free Ampere VM in Mumbai (`ap-mumbai-1`). It provides independent external health probing and dispatches immediate downtime notifications to Slack channel `#homelab-alerts`.

## Deployment
1. SSH into the OCI Ampere VM:
   ```bash
   ssh ubuntu@<OCI_VM_PUBLIC_OR_TAILSCALE_IP>
   ```
2. Clone or copy this directory:
   ```bash
   mkdir -p ~/uptime-kuma
   cd ~/uptime-kuma
   ```
3. Launch Uptime Kuma:
   ```bash
   docker compose up -d
   ```
4. Access the web interface at `http://<OCI_VM_IP>:3001` or via Cloudflare Tunnel (`status.vijaysingh.cloud`).

## Configured Monitors
| Monitor Name | Type | Target URL / Host | Interval |
| :--- | :--- | :--- | :--- |
| **Homelab Documentation** | HTTP(s) | `https://docs.vijaysingh.cloud` | 60s |
| **n8n Webhook Engine** | HTTP(s) | `https://hooks.vijaysingh.cloud` | 60s |
| **Homepage Command Center** | HTTP(s) | `https://hub.vijaysingh.cloud` | 60s |
| **Paperless OCR Archive** | HTTP(s) | `https://docs-ocr.vijaysingh.cloud` | 60s |
| **Miniflux RSS** | HTTP(s) | `https://rss.vijaysingh.cloud` | 60s |
| **Homelab Router (Tailscale)**| Ping | Router Tailscale IP | 30s |

## Notification Target
- **Channel:** `#homelab-alerts`
- **Method:** Incoming Webhook (Slack App)
