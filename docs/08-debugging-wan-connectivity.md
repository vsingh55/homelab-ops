# 08. Debugging WAN Connectivity Barrier

**Incident:** Ansible Automation failing from external networks (WAN) while operational on LAN.

**Skills Deployed:** Network Tracing, SSH Tunneling, Split-Horizon DNS, Log Analysis.

## 1. The Incident
**Observation:**
While working from a remote location (Coffee Shop), the Ansible control plane (Laptop) failed to connect to the infrastructure.
* `ops-center` (Management Node): `UNREACHABLE`
* `k3s-prod` (Internal Node): `Connection closed by UNKNOWN port 65535`

**Initial Hypothesis:**
Tailscale mesh network failure or Firewall blocking the connection.

## 2. The Investigation

### Step 1: Log Analysis
The Ansible error logs provided the smoking gun:
```text
fatal: [ops-center]: ... ssh: connect to host 192.168.0.5 port 22: Connection timed out
```
**Analysis:** The laptop was attempting to connect to the LAN IP (192.168.0.5) of the Management Node. Since 192.168.0.0/24 is a non-routable private range on the public internet, the packet was dropped.

### Step 2: The "Jump Host" Paradox
Even though the Internal Nodes (k3s-prod) were configured to tunnel via ops-center, they failed because the Entry Gate (ops-center) itself was unreachable.

**Analogy**: You cannot walk through a hallway (Tunnel) if you cannot open the front door (Ops-Center).

### Step 3: Root Cause Discovery
The issue was a Split-Horizon Configuration Conflict.

**Terraform Provisioning:** Had injected a local optimization into ~/.ssh/config forcing ops-center to resolve to 192.168.x.x (LAN IP).

**Ansible Inventory:** Was configured to use the hostname ops-center.

**Conflict**: When on WAN, SSH obeyed the config file and targeted the dead LAN IP instead of the active Tailscale IP.

## 3. The Solution
**Fix 1: SSH Config Override** 

Modified the Control Node's SSH configuration to enforce the Zero-Trust path.

>Old: HostName 192.x.x.x (LAN Dependency)

>New: HostName 100.x.x.x (Tailscale Overlay Network)

**Fix 2: Tunnel Enforcement**
Updated Ansible Group Variables to ensure all traffic—even to the Hypervisor—is routed through the secure tunnel.

*File*: inventory/group_vars/hypervisor.yml

```YAML

ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q devops@ops-center"'
```

## 4. Outcome
**Connectivity:**: 100% Success rate from external networks.

**Security:** Zero ports exposed on the Home Router. All traffic is encapsulated in WireGuard (Tailscale) tunnels.

**Resilience:** Infrastructure is now location-agnostic.