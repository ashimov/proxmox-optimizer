<div align="center">

# 🚀 Proxmox Optimizer

### Professional Scripts for Installing, Optimizing and Managing Proxmox VE

[![License: BSD](https://img.shields.io/badge/License-BSD-blue.svg)](LICENSE)
[![Proxmox VE 9.x](https://img.shields.io/badge/Proxmox%20VE-9.x-orange.svg)](https://www.proxmox.com/)
[![Proxmox VE 8.x](https://img.shields.io/badge/Proxmox%20VE-8.x-green.svg)](https://www.proxmox.com/)
[![PBS 3.x](https://img.shields.io/badge/PBS-3.x-purple.svg)](https://www.proxmox.com/en/proxmox-backup-server)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen.svg)](https://github.com/ashimov)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)](https://github.com/ashimov/proxmox-optimizer/pulls)

*Turn your fresh Proxmox installation into an optimized, secure, and high-performance virtualization host*

---

**[📖 Documentation](#-table-of-contents)** • **[🚀 Quick Start](#-quick-start)** • **[💡 Features](#-features)** • **[🤝 Contributing](#-contributing)**

</div>

---

## 📋 Table of Contents

- [🎯 Supported Versions](#-supported-versions)
- [🚀 Quick Start](#-quick-start)
- [🧰 Ansible Automation](#-ansible-automation)
- [💡 Features](#-features)
- [📦 Installation Scripts](#-installation-scripts)
  - [Post-Installation Optimizer](#-post-installation-optimizer)
  - [Debian to Proxmox Conversion](#-debian-to-proxmox-conversion)
- [🌐 Hosting Provider Guides](#-hosting-provider-guides)
  - [Hetzner](#hetzner-installation)
  - [OVH](#ovh-installation)
- [💾 ZFS Management](#-zfs-management)
- [🔌 Networking](#-networking)
- [🛠️ Helper Scripts](#️-helper-scripts)
- [📝 Additional Notes](#-additional-notes)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

## 🎯 Supported Versions

| Platform | Version | Debian | Status |
|----------|---------|--------|--------|
| **Proxmox VE** | 9.x | Trixie (13) | ✅ Fully Supported |
| **Proxmox VE** | 8.x | Bookworm (12) | ✅ Fully Supported |
| **Proxmox Backup Server** | 3.x | Bookworm (12) | ✅ Fully Supported |

---

## 🚀 Quick Start

### One-Line Installation

Run this command on a fresh Proxmox installation to apply all optimizations:

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh -c -O install-post.sh && bash install-post.sh && rm install-post.sh
```

> 💡 **Note:** Reboot after installation to apply all changes.

---

## 🧰 Ansible Automation

For repeatable, idempotent automation, use the Ansible roles and playbooks in `ansible/`.

### Requirements

- Full `ansible` package (ansible-core is not supported)
- Python 3.11+
- Collections: `ansible.utils`, `ansible.posix`

### Quick Start

```bash
cd ansible

# Install required collections
ansible-galaxy collection install -r collections/requirements.yml

# Configure inventory
cp inventory/hosts.ini.example inventory/hosts.ini
nano inventory/hosts.ini

# Run full optimization
ansible-playbook playbooks/proxmox.yml -i inventory/hosts.ini
```

### Available Roles

| Role                    | Description                                |
|-------------------------|--------------------------------------------|
| `proxmox_base`          | Repositories, packages, APT configuration  |
| `proxmox_security`      | Fail2ban, Lynis, rpcbind hardening         |
| `proxmox_tuning`        | Sysctl, journald, KSM, MOTD, limits        |
| `proxmox_zfs`           | ZFS ARC tuning, auto-snapshots             |
| `proxmox_vfio`          | IOMMU, VFIO for PCIe passthrough           |
| `proxmox_networking`    | vmbr0 routed bridge configuration          |
| `proxmox_lxc_docker`    | Docker support for LXC containers          |
| `proxmox_nvidia`        | NVIDIA Docker runtime for GPU passthrough  |
| `proxmox_zfs_slog_cache`| Convert MD RAID to ZFS SLOG/cache          |
| `proxmox_tinc_vpn`      | Tinc VPN mesh network for clusters         |
| `provider_ovh`          | OVH RTM installer, auto-detection          |
| `provider_hetzner`      | Hetzner network tuning, Storage Box        |

### Configuration

All variables can be customized in `inventory/group_vars/all.yml`:

```yaml
# Security
xs_fail2ban: "yes"
xs_disablerpc: "yes"
xs_lynis: "yes"

# Performance
xs_tcpbbr: "yes"
xs_ksmtuned: "yes"
xs_pigz: "yes"

# ZFS
xs_zfsarc: "yes"
xs_zfsautosnapshot: "no"
```

### Dangerous Operations

Some playbooks perform destructive operations and require explicit confirmation:

```bash
# Network configuration (overwrites /etc/network/interfaces)
ansible-playbook playbooks/network-configure.yml -e dangerous_confirm=yes

# LVM to ZFS conversion
ansible-playbook playbooks/lvm-to-zfs.yml -e dangerous_confirm=yes

# ZFS pool creation
ansible-playbook playbooks/zfs-create.yml -e dangerous_confirm=yes

# ZFS SLOG/cache (converts MD RAID - destructive!)
ansible-playbook playbooks/zfs-slog-cache.yml

# Docker in LXC (security-sensitive)
ansible-playbook playbooks/lxc-docker.yml -e lxc_docker_container_id=100 -e lxc_docker_confirm=true
```

### Tinc VPN Mesh Setup

Deploy Tinc VPN across multiple nodes:

```bash
# Configure inventory with per-host variables
# inventory/hosts.ini:
# [proxmox_nodes]
# node1 tinc_vpn_ip_last=1 tinc_connect_to=node2
# node2 tinc_vpn_ip_last=2 tinc_connect_to=node3
# node3 tinc_vpn_ip_last=3 tinc_connect_to=node1

ansible-playbook playbooks/tinc-vpn.yml -i inventory/hosts.ini
```

### Secrets Management

Never store credentials in version control. Use `host_vars/` with ansible-vault:

```bash
# Create encrypted host vars
ansible-vault create inventory/host_vars/myhost/vault.yml

# Run playbook with vault
ansible-playbook playbooks/proxmox.yml --ask-vault-pass
```

### Documentation

- [ansible/README.md](ansible/README.md) - Full Ansible documentation
- [MIGRATION.md](MIGRATION.md) - Migration guide from shell scripts
- [ansible/playbooks/README.md](ansible/playbooks/README.md) - Playbook reference

## 💡 Features

The post-installation script (`install-post.sh`) transforms your Proxmox host with:

<table>
<tr>
<td width="50%">

### 🔒 Security Hardening
- ✅ Fail2ban protection for web interface
- ✅ Disable portmapper/rpcbind
- ✅ Lynis security scan tool
- ✅ Kernel panic auto-reboot
- ✅ Network security optimizations

### ⚡ Performance Tuning
- ✅ TCP BBR congestion control
- ✅ TCP FastOpen enabled
- ✅ Memory optimization
- ✅ ZFS ARC size auto-tuning
- ✅ Vzdump backup speed increase
- ✅ Pigz (parallel gzip) compression

</td>
<td width="50%">

### 🛠️ System Enhancements
- ✅ AMD EPYC/Ryzen CPU fixes
- ✅ KSM memory tuning
- ✅ Journald optimization
- ✅ Logrotate configuration
- ✅ Entropy pool management
- ✅ VFIO IOMMU for PCIe passthrough

### 📦 Package Management
- ✅ Enterprise repo disabled
- ✅ Subscription banner removed
- ✅ Public repos enabled
- ✅ Essential utilities installed
- ✅ Ceph integration (optional)

</td>
</tr>
</table>

---

## 📦 Installation Scripts

### 🔧 Post-Installation Optimizer

The main optimization script that configures over 30+ system improvements.

#### Standard Installation
```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh -c -O install-post.sh
bash install-post.sh
```

#### Custom Configuration

Create a configuration file for custom options:

```bash
# Download sample configuration
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.env.sample -c -O install-post.env

# Edit configuration
nano install-post.env

# Run with custom settings
bash install-post.sh
```

#### Environment Variable Override

```bash
# Example: Disable MOTD banner
export XS_MOTD="no"
bash install-post.sh
```

#### Logging

By default, output is written to `/var/log/ashimov-install-post.log`. Disable or change it with:
```bash
export XS_LOG_FILE=""
export XS_LOG_FILE="/path/to/custom.log"
```

<details>
<summary>📋 <b>Click to view all configuration options</b></summary>

| Variable | Default | Description |
|----------|---------|-------------|
| `XS_AMDFIXES` | yes | AMD EPYC/Ryzen CPU optimizations |
| `XS_APTIPV4` | yes | Force APT to use IPv4 |
| `XS_APTUPGRADE` | yes | Update system packages |
| `XS_BASHRC` | yes | Customize bash shell |
| `XS_CEPH` | no | Install Ceph storage |
| `XS_DISABLERPC` | yes | Disable portmapper/rpcbind |
| `XS_ENTROPY` | yes | Entropy pool management |
| `XS_FAIL2BAN` | yes | Web interface protection |
| `XS_GUESTAGENT` | yes | VM guest agent detection |
| `XS_IFUPDOWN2` | yes | Rebootless networking |
| `XS_JOURNALD` | yes | Optimize journald |
| `XS_KERNELHEADERS` | yes | Install kernel headers |
| `XS_KERNELPANIC` | yes | Auto-reboot on panic |
| `XS_KSMTUNED` | yes | KSM memory optimization |
| `XS_LIMITS` | yes | Increase system limits |
| `XS_LOGROTATE` | yes | Optimize log rotation |
| `XS_LOG_FILE` | /var/log/ashimov-install-post.log | Install-post log file (empty to disable) |
| `XS_LYNIS` | yes | Security scanning tool |
| `XS_CISOFY_KEY_URL` | https://packages.cisofy.com/keys/cisofy-software-public.key | Override Cisofy key URL |
| `XS_MAXFS` | yes | Increase FS limits |
| `XS_MEMORYFIXES` | yes | Memory optimizations |
| `XS_MOTD` | yes | Custom MOTD banner |
| `XS_NET` | yes | Network optimizations |
| `XS_MANAGE_SOURCES_LIST` | yes | Manage /etc/apt/sources.list (clean installs) |
| `XS_NOENTREPO` | yes | Disable enterprise repo |
| `XS_PROXMOX_KEY_URL` | empty | Override Proxmox key URL (auto by OS codename if empty) |
| `XS_NOSUBBANNER` | yes | Remove subscription banner |
| `XS_OPENVSWITCH` | no | Install Open vSwitch |
| `XS_OVHRTM` | yes | OVH RTM monitoring |
| `XS_OVHRTM_ALLOW_UNVERIFIED` | no | Allow running OVH RTM installer without checksum verification |
| `XS_OVHRTM_SHA256` | empty | SHA256 checksum for OVH RTM installer (recommended) |
| `XS_OVHRTM_URL` | https://last-public-ovh-infra-yak.snap.mirrors.ovh.net/yak/archives/apply.sh | Override OVH RTM installer URL |
| `XS_PIGZ` | yes | Parallel gzip compression |
| `XS_SWAPPINESS` | yes | Fix high swap usage |
| `XS_TCPBBR` | yes | TCP BBR congestion control |
| `XS_TCPFASTOPEN` | yes | TCP FastOpen |
| `XS_TESTREPO` | no | Enable testing repo |
| `XS_TIMESYNC` | yes | NTP time sync |
| `XS_TIMEZONE` | auto | Set timezone by IP |
| `XS_IPINFO_URL` | https://ipinfo.io/ip | Override public IP lookup endpoint |
| `XS_IPAPI_URL` | https://ipapi.co | Override timezone lookup base URL |
| `XS_UTILS` | yes | Install system utilities |
| `XS_VZDUMP` | yes | Optimize backup speed |
| `XS_ZFSARC` | yes | ZFS ARC optimization |
| `XS_ZFSAUTOSNAPSHOT` | no | ZFS auto-snapshots |
| `XS_VFIO_IOMMU` | yes | PCIe passthrough support |

</details>

---

### 🔄 Debian to Proxmox Conversion

Convert a clean Debian installation to Proxmox VE.

#### Debian 13 → Proxmox VE 9 ⭐ Recommended
```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian13-2-proxmox9.sh
chmod +x debian13-2-proxmox9.sh
./debian13-2-proxmox9.sh
```

#### Debian 12 → Proxmox VE 8
```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian12-2-proxmox8.sh
chmod +x debian12-2-proxmox8.sh
./debian12-2-proxmox8.sh
```

**Note:** To allow the conversion scripts to download `install-post.sh`, set `XS_ALLOW_REMOTE_INSTALL_POST=yes` and `XS_INSTALL_POST_SHA256=<expected_sha256>`.

**Prerequisites:**
- Clean Debian installation with valid FQDN hostname
- Tested on KVM, VirtualBox, and Dedicated Servers
- Automatically handles cloud-init and `/etc/hosts` configuration
- Runs post-installation optimizer automatically (local `install-post.sh` or allow remote download with checksum)

---

## 🌐 Hosting Provider Guides

### Hetzner Installation

Detailed guide for Hetzner dedicated servers: [📖 Hetzner README](hetzner/README.md)

#### VNC Installation (Native ISO Install)
```bash
# Proxmox VE 8 (default)
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/hetzner/vnc-install-proxmox.sh
chmod +x vnc-install-proxmox.sh
./vnc-install-proxmox.sh

# Proxmox VE 9
./vnc-install-proxmox.sh pve9

# Proxmox Backup Server
./vnc-install-proxmox.sh pbs
```

#### Installimage Automated Installation
```bash
# From Hetzner Rescue System
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/hetzner/installimage-proxmox.sh -c -O installimage-proxmox.sh
chmod +x installimage-proxmox.sh

# Proxmox VE 8
./installimage-proxmox.sh "your.hostname.fqdn"

# Proxmox VE 9
./installimage-proxmox.sh "your.hostname.fqdn" pve9

# Proxmox Backup Server
./installimage-proxmox.sh "your.hostname.fqdn" pbs
```

### OVH Installation

Detailed guide for OVH dedicated servers: [📖 OVH README](ovh/README.md)

**Quick Setup:**
1. Select **Install from OVH template** → **VPS Proxmox VE**
2. Configure partitions (see guide for recommended layout)
3. Set installation script URL: `https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh`
4. After installation, run LVM to ZFS conversion and networking scripts

---

## 💾 ZFS Management

### LVM to ZFS Conversion

Convert MDADM-based LVM to ZFS with automatic RAID level detection.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/lvm-2-zfs.sh -c -O lvm-2-zfs.sh
chmod +x lvm-2-zfs.sh
./lvm-2-zfs.sh [LVM_MOUNT_POINT]
```

**Creates:**
- `zfsbackup` (rpool/backup)
- `zfsvmdata` (rpool/vmdata)
- `/var/lib/vz/tmp_backup` (rpool/tmp_backup)

### Create ZFS Pool

Create ZFS pool from specified devices with automatic RAID detection.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/createzfs.sh -c -O createzfs.sh
chmod +x createzfs.sh
ZFS_CONFIRM=yes ./createzfs.sh poolname /dev/sda /dev/sdb
ZFS_DRYRUN=yes ./createzfs.sh poolname /dev/sda /dev/sdb
```
Dry-run prints planned actions and exits non-zero without changes.

**RAID Level Detection:**
| Drives | RAID Level | Type |
|--------|------------|------|
| 1 | zfs | Single |
| 2 | mirror | RAID1 |
| 3-5 | raidz-1 | RAID5 |
| 6-10 | raidz-2 | RAID6 |
| 11+ | raidz-3 | RAID7 |

### ZFS Cache and SLOG

Add L2ARC cache and SLOG to existing ZFS pool.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/slog-cache-2-zfs.sh -c -O slog-cache-2-zfs.sh
chmod +x slog-cache-2-zfs.sh
./slog-cache-2-zfs.sh poolname
```

### ZFS Benchmark

Test ZFS performance with various write patterns.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/benchmark_zfs.sh -c -O benchmark_zfs.sh
chmod +x benchmark_zfs.sh
./benchmark_zfs.sh
```

---

## 🔌 Networking

### Network Configuration

Create routed vmbr0 network bridge for Proxmox VMs.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/networking/network-configure.sh -c -O network-configure.sh
chmod +x network-configure.sh
./network-configure.sh
```

**Features:**

- **vmbr0 (Routed):** Public IPs routed through physical interface
- Auto-detects interface, gateway, and netmask
- Supports IPv4 and IPv6
- Creates backup of existing configuration

### Tinc VPN

Create private mesh VPN for cluster communication with multicast support.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/networking/tincvpn.sh -c -O tincvpn.sh
chmod +x tincvpn.sh
./tincvpn.sh -h
```

**3-Node Cluster Example:**

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

---

## 🛠️ Helper Scripts

### Enable Docker in LXC Container

> ⚠️ **Security Warning:** Running Docker in LXC requires elevated privileges.

```bash
curl https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/helpers/pve-enable-lxc-docker.sh --output /usr/sbin/pve-enable-lxc-docker
chmod +x /usr/sbin/pve-enable-lxc-docker
pve-enable-lxc-docker <container_id>
```

> 💡 **Recommendation:** Use a dedicated VM for Docker instead of LXC containers.

---

## 📝 Additional Notes

### Recommended Partitioning Scheme

| Partition | Size | Filesystem | Mount Point |
|-----------|------|------------|-------------|
| Root | 40 GB | ext4 (RAID1) | / |
| ZFS Cache* | 30 GB | ext4 (RAID1) | /xshok/zfs-cache |
| ZFS SLOG* | 5 GB | ext4 (RAID1) | /xshok/zfs-slog |
| Swap | 16-64 GB** | swap | - |
| Data | Remaining | xfs (LVM) | /var/lib/vz |

*\*Only for SSD with HDD pool*
*\*\*Based on RAM: <64GB=32GB swap, ≥64GB=64GB swap*

### Alpine Linux QEMU Guest Agent

```bash
apk update && apk add qemu-guest-agent acpi
echo 'GA_PATH="/dev/vport2p1"' >> /etc/conf.d/qemu-guest-agent
rc-update add qemu-guest-agent default
rc-update add acpid default
/etc/init.d/qemu-guest-agent restart
```

### Proxmox ACME/Let's Encrypt

```bash
pvenode acme account register default mail@example.com
pvenode config set --acme domains=proxmox.example.com
pvenode acme cert order
```

### ZFS Snapshot Commands

```bash
# List all snapshots
zfs list -t snapshot

# Create pre-rollback snapshot
zfs-auto-snapshot --verbose --label=prerollback -r //

# Rollback to snapshot
zfs rollback <snapshotname>
```

---

## 🔐 Security: Script Verification

For security, always verify downloaded scripts before execution. Use SHA256 checksums to ensure script integrity.

### Verifying Scripts

```bash
# Download the script
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh

# Generate checksum and compare with published value
sha256sum install-post.sh

# Or verify in one command (replace EXPECTED_CHECKSUM with actual value)
echo "EXPECTED_CHECKSUM  install-post.sh" | sha256sum -c -
```

### Environment Variables for Checksum Verification

| Script | Checksum Variable | Allow Unverified Variable |
|--------|-------------------|---------------------------|
| `install-post.sh` | `XS_INSTALL_POST_SHA256` | `XS_ALLOW_REMOTE_INSTALL_POST` |
| OVH RTM installer | `XS_OVHRTM_SHA256` | `XS_OVHRTM_ALLOW_UNVERIFIED` |
| Hetzner post-install | `MY_POSTINSTALL_SHA256` | `MY_POSTINSTALL_ALLOW_UNVERIFIED` |

### Example: Secure Remote Installation

```bash
# Set the expected SHA256 checksum (get from releases or compute yourself)
export XS_INSTALL_POST_SHA256="your_checksum_here"
export XS_ALLOW_REMOTE_INSTALL_POST="yes"

# Run the conversion script - it will verify the checksum before execution
./debian12-2-proxmox8.sh
```

> ⚠️ **Important**: Never set `*_ALLOW_UNVERIFIED=yes` in production. Always use checksums.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit Pull Requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the **BSD License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### 👨‍💻 Maintained by [ashimov](https://github.com/ashimov)

---

**⭐ Star this repo if you find it useful!**

</div>
