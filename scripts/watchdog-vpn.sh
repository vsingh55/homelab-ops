#!/bin/bash
# ------------------------------------------------------------------
# Watchdog: Hybrid Cloud VPN Healer
# ------------------------------------------------------------------

# 1. Securely Load Configuration
# Look for the config file in the same directory as this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/watchdog.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Critical Error: Config file not found at $CONFIG_FILE"
    echo "   Please copy watchdog.conf.example to watchdog.conf and configure it."
    exit 1
fi

source "$CONFIG_FILE"

# ------------------------------------------------------------------
# Logic (No Secrets Below This Line)
# ------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 2. Check Connectivity
ping -c 3 -W 5 "$VPN_IP" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    exit 0
fi

log "❌ VPN Down! Initiating Recovery for $GCP_VM_NAME..."

# 3. Check VM Status
STATUS=$(gcloud compute instances describe "$GCP_VM_NAME" --zone="$GCP_ZONE" --format="get(status)")
log "Current VM Status: $STATUS"

if [ "$STATUS" == "TERMINATED" ]; then
    log "⚡ VM was preempted. Starting it up..."
    gcloud compute instances start "$GCP_VM_NAME" --zone="$GCP_ZONE"
    sleep 30 # Wait for boot
elif [ "$STATUS" == "RUNNING" ]; then
    log "⚠️ VM is running but unreachable. VPN service might be down."
fi

# 4. Get New Public IP
NEW_IP=$(gcloud compute instances describe "$GCP_VM_NAME" --zone="$GCP_ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
log "New Public IP: $NEW_IP"

# 5. Update Inventory (Using the path from config)
sed -i "s/ansible_host: [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/ansible_host: $NEW_IP/" "$INVENTORY_FILE"

# 6. Re-run Ansible
log "🔄 Re-running Ansible configuration..."
# We assume the playbook path relative to the inventory location defined in config
# Or you can add PLAYBOOK_DIR to the config file for extra safety.
cd "$(dirname "$INVENTORY_FILE")/../" || exit 1
ansible-playbook playbooks/setup_hybrid_vpn.yml -i inventory/hosts.yml >> "$LOG_FILE" 2>&1

log "✅ Recovery Complete."