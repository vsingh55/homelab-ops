import re

with open("inventory/hosts.yml", "r") as f:
    c = f.read()

c = c.replace("ansible_host: 192.168.x.x", "ansible_host: 192.168.1.x")
c = re.sub(r'pve:\s+ansible_host: 192.168.1.x', 'pve:\n          ansible_host: 192.168.1.3', c)
c = re.sub(r'k3s-prod:\s+ansible_host: 192.168.1.x', 'k3s-prod:\n          ansible_host: 192.168.1.30\n          vpn_ip: 10.100.0.3\n          vpn_peer_ip: 10.100.0.1', c)
c = re.sub(r'gateway:\s+ansible_host: 192.168.1.x', 'gateway:\n              ansible_host: 192.168.1.10', c)
c = re.sub(r'jumpbox:\s+ansible_host: 192.168.1.x', 'jumpbox:\n              ansible_host: 192.168.1.20', c)
c = re.sub(r'server:\s+ansible_host: 192.168.1.x', 'server:\n              ansible_host: 192.168.1.21', c)
c = re.sub(r'node-0:\s+ansible_host: 192.168.1.x', 'node-0:\n              ansible_host: 192.168.1.22', c)
c = re.sub(r'node-1:\s+ansible_host: 192.168.1.x', 'node-1:\n              ansible_host: 192.168.1.23', c)

c = c.replace("vpn_ip: 10.100.x.x", "vpn_ip: 10.100.0.2", 1) # ops-center
c = c.replace("vpn_peer_ip: 10.100.x.x", "vpn_peer_ip: 10.100.0.1", 1) # ops-center

c = c.replace("vpn_ip: 10.100.x.x", "vpn_ip: 10.100.0.1", 1) # gateway
c = c.replace("vpn_peer_ip: 10.100.x.x", "vpn_peer_ip: 10.100.0.3", 1) # gateway

with open("inventory/hosts.yml", "w") as f:
    f.write(c)

