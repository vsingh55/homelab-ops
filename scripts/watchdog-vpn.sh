#!/bin/bash
# ------------------------------------------------------------------
# Watchdog: Hybrid Cloud VPN Healer (Cloudflare Edition)
# ------------------------------------------------------------------

# 1. Securely Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/watchdog.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Critical Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# --- HELPER FUNCTIONS ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

update_cloudflare_dns() {
    local ip=$1
    local record_name="hooks.vijaysingh.cloud"
    
    # Ensure these are in your watchdog.conf
    # CF_ZONE_ID="your_zone_id_here"
    # CF_API_TOKEN="your_api_token_here"

    log "☁️ Checking Cloudflare DNS for $record_name..."

    # Check if record exists and get its ID
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$record_name" \
         -H "Authorization: Bearer $CF_API_TOKEN" \
         -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)

    if [ -z "$RECORD_ID" ]; then
        log "⚠️ Record not found. Creating new record..."
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
             -H "Authorization: Bearer $CF_API_TOKEN" \
             -H "Content-Type: application/json" \
             --data '{"type":"A","name":"'"$record_name"'","content":"'"$ip"'","ttl":120,"proxied":false}' > /dev/null
    else
        log "🔄 Updating existing Record ID: $RECORD_ID to $ip"
        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
             -H "Authorization: Bearer $CF_API_TOKEN" \
             -H "Content-Type: application/json" \
             --data '{"type":"A","name":"'"$record_name"'","content":"'"$ip"'","ttl":120,"proxied":false}' > /dev/null
    fi
    log "✅ Cloudflare DNS Updated."
}

# ------------------------------------------------------------------
# MAIN LOGIC
# ------------------------------------------------------------------

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

# 5. Update Inventory
sed -i "s/ansible_host: .* # DYNAMIC_IP/ansible_host: $NEW_IP # DYNAMIC_IP/" "$INVENTORY_FILE"

# 6. Update DNS (The New Step)
update_cloudflare_dns "$NEW_IP"

# 7. Re-run Ansible
log "🔄 Re-running Ansible configuration..."
cd "$(dirname "$INVENTORY_FILE")/../" || exit 1
ansible-playbook playbooks/setup_hybrid_vpn.yml -i inventory/hosts.yml >> "$LOG_FILE" 2>&1

log "✅ Recovery Complete."