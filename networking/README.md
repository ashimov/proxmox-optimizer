# Networking Scripts

## Overview

Collection of networking scripts for Proxmox VE configuration.

> **Recommended:** Use Ansible roles for repeatable, idempotent deployments.
> See [ansible/README.md](../ansible/README.md) for details.

## Ansible Roles

| Role | Description | Playbook |
|------|-------------|----------|
| `proxmox_networking` | Routed vmbr0 bridge configuration | `playbooks/network-configure.yml` |
| `proxmox_tinc_vpn` | Tinc VPN mesh network | `playbooks/tinc-vpn.yml` |

### Ansible Usage

```bash
cd ansible

# Network configuration
ansible-playbook playbooks/network-configure.yml -e dangerous_confirm=yes

# Tinc VPN mesh (configure per-host variables in inventory)
ansible-playbook playbooks/tinc-vpn.yml -i inventory/hosts.ini
```

### Tinc VPN Inventory Example

```ini
[proxmox]
node1 tinc_vpn_ip_last=1 tinc_connect_to=node2
node2 tinc_vpn_ip_last=2 tinc_connect_to=node3
node3 tinc_vpn_ip_last=3 tinc_connect_to=node1
```

The play runs `serial: 1`, collects each node's host file into
`ansible/tinc_hosts/`, then copies them to every other node.

## Shell Scripts

| Script | Description |
|--------|-------------|
| `network-configure.sh` | Creates routed network bridge (vmbr0) for Proxmox |
| `tincvpn.sh` | Creates private mesh VPN for cluster communication |

## network-configure.sh

Creates a routed network configuration with:

- **vmbr0 (Routed):** Public IPs with physical interface MAC address
- Auto-detects interface, gateway, and netmask
- Supports IPv4 and IPv6
- Creates backup of existing configuration

### Usage

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/networking/network-configure.sh
chmod +x network-configure.sh
./network-configure.sh
```

The script overwrites `/etc/network/interfaces` and saves the old one as
`/etc/network/interfaces.<timestamp>`. The new config only takes effect on
reboot or `ifreload -a`, so check it before you restart networking.

## tincvpn.sh

Creates a mesh VPN with multicast support, for corosync/Ceph traffic between
nodes. Config lives in `/etc/tinc/pvemesh`, the unit is `tinc-pvemesh.service`.

Cipher and digest are pinned to `aes-256-cbc` and `sha256`, and compression is
off. Every node in the mesh has to agree on those three values, so if you are
adding a node to an older mesh, either update all of them or match the old
settings in `/etc/tinc/pvemesh/tinc.conf`.

Tinc 1.0 has no forward secrecy. For a new deployment WireGuard is the better
answer; this script exists for the clusters that already run tinc.

### Usage

```bash
./tincvpn.sh -i <ip_last_octet> -c <connect_to_host> [-p port] [-a public_ip]
```

### Options

| Option | Description |
|--------|-------------|
| `-i` | Last octet of VPN IP address (1-254) |
| `-c` | Host to connect to (from /etc/hosts) |
| `-p` | Port number (default: 655) |
| `-a` | Public IP address (auto-detected if not set) |
| `-r` | Reset configuration |
| `-u` | Uninstall tinc |

### Example: 3-Node Cluster

```bash
# /etc/hosts on all nodes
11.11.11.11 host1
22.22.22.22 host2
33.33.33.33 host3

# Host 1
./tincvpn.sh -i 1 -c host2

# Host 2
./tincvpn.sh -i 2 -c host3

# Host 3
./tincvpn.sh -i 3 -c host1
```

After running on each node, copy the host block it prints to the other nodes.
The same block is saved at `/etc/tinc/pvemesh/this_host.info`.

`-r` rewrites the config, `-u` stops and removes it. Both keep the RSA keys.

---

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
