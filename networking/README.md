# 🌐 Networking Scripts

## Overview

Collection of networking scripts for Proxmox VE configuration.

## Scripts

| Script | Description |
|--------|-------------|
| `network-configure.sh` | Creates routed (vmbr0) and NAT (vmbr1) network bridges |
| `network-addiprange.sh` | Adds additional IP ranges to network configuration |
| `tincvpn.sh` | Creates private mesh VPN for cluster communication |

## network-configure.sh

Creates a complete network configuration with:
- **vmbr0 (Routed):** Public IPs with physical interface MAC address
- **vmbr1 (NAT):** Private network 10.10.10.0/24 with DHCP

### Usage
```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/networking/network-configure.sh
chmod +x network-configure.sh
./network-configure.sh
```

## network-addiprange.sh

Adds additional IP ranges to your network configuration.

### Usage
```bash
./network-addiprange.sh ip.xx.xx.xx/cidr [interface]
```

## tincvpn.sh

Creates a mesh VPN network with multicast support, ideal for Proxmox clustering.

### Usage
```bash
./tincvpn.sh -i <ip_last_octet> -c <connect_to_host> [-p port] [-a public_ip]
```

---
*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
