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

### Installation

The scripts run as **root** and reconfigure the host. Download, verify, then
execute - never pipe an unverified script from the network into a shell.

```bash
# 1. Pick a release tag (not 'master': that branch moves under you)
RELEASE="v1.0.4"
BASE="https://raw.githubusercontent.com/ashimov/proxmox-optimizer/${RELEASE}"

# 2. Download the script and the published checksum list
wget "${BASE}/install-post.sh" -O install-post.sh
wget "https://github.com/ashimov/proxmox-optimizer/releases/download/${RELEASE}/SHA256SUMS" -O SHA256SUMS

# 3. Verify BEFORE running anything
sha256sum --ignore-missing -c SHA256SUMS

# 4. Only then execute
bash install-post.sh
```

> ⚠️ **Do not use `wget -c`** when fetching these scripts. If a partial file is
> already present, `-c` appends to it and you end up executing a spliced script.

> 💡 **Note:** Reboot after installation to apply all changes.

<details>
<summary>Cloning the repository instead (recommended for Ansible users)</summary>

```bash
git clone --branch v1.0.4 https://github.com/ashimov/proxmox-optimizer.git
cd proxmox-optimizer
git verify-tag v1.0.4    # if the tag is signed
bash install-post.sh
```

</details>

---

## 🧰 Ansible Automation

For repeatable, idempotent automation, use the Ansible roles and playbooks in `ansible/`.

### Requirements

- Full `ansible` package (ansible-core is not supported)
- Python 3.11+
- `netaddr` on the control node, needed by the `ipaddr` filter
- Collections: `ansible.utils`, `ansible.posix`, `community.general`

```bash
pip install -r ansible/requirements.txt
ansible-galaxy collection install -r ansible/collections/requirements.yml
```

### Quick Start

```bash
cd ansible

# Install required collections
ansible-galaxy collection install -r collections/requirements.yml

# Configure inventory (hosts.ini itself is git-ignored)
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
| `proxmox_ssh`           | sshd policy, keys instead of passwords     |
| `proxmox_updates`       | unattended security updates                |
| `proxmox_firewall`      | pve-firewall rules for the management ports|
| `proxmox_notifications` | Mail alerts from ZFS, smartd and Proxmox   |
| `proxmox_backup`        | PBS storage and a vzdump job               |
| `proxmox_networking`    | vmbr0 routed bridge configuration          |
| `proxmox_lxc_docker`    | Docker support for LXC containers          |
| `proxmox_nvidia`        | NVIDIA Container Toolkit for Docker        |
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
xs_coredump: "no"

# Performance
xs_tcpbbr: "yes"
xs_ksmtuned: "yes"
xs_pigz: "yes"
xs_hugepages: ""      # page count, empty = do not preallocate

# ZFS
xs_zfsarc: "yes"
xs_zfsautosnapshot: "no"
```

The full list with defaults is in `inventory/group_vars/all.yml` and in each
role's `defaults/main.yml`.

### Dangerous Operations

> ⚠️ **DESTRUCTIVE: DATA LOSS RISK**
>
> The playbooks below rewrite block devices, partition tables, or network
> configuration. A typo in inventory or a stale `dangerous_confirm` will
> wipe data or lock you out over SSH. **Always**:
>
> - Take a full backup or snapshot first.
> - Run with `--check --diff` once before applying.
> - Keep an out-of-band console (IPMI, KVM, rescue mode) open.

```bash
# Network configuration (overwrites /etc/network/interfaces, can break SSH)
ansible-playbook playbooks/network-configure.yml -e dangerous_confirm=yes

# LVM to ZFS conversion (DESTROYS LVM data)
ansible-playbook playbooks/lvm-to-zfs.yml -e dangerous_confirm=yes

# ZFS pool creation (wipes target devices)
ansible-playbook playbooks/zfs-create.yml -e dangerous_confirm=yes

# ZFS SLOG/cache (destroys the MD arrays it converts)
ansible-playbook playbooks/zfs-slog-cache.yml -e zfs_slog_cache_confirm=true

# Docker in LXC (security-sensitive: drops most container isolation)
ansible-playbook playbooks/lxc-docker.yml -e lxc_docker_container_id=100 -e lxc_docker_confirm=true
```

The shell scripts have their own gates, so running them by hand needs the
matching variable:

```bash
LVM2ZFS_CONFIRM=yes ./zfs/lvm-2-zfs.sh /var/lib/vz
ZFS_CONFIRM=yes ./zfs/createzfs.sh hdd /dev/sda /dev/sdb
ZFS_DRYRUN=yes ./zfs/createzfs.sh hdd /dev/sda /dev/sdb   # prints, changes nothing
LXC_DOCKER_CONFIRM=yes pve-enable-lxc-docker 100
INSTALL_CONFIRM=yes ./hetzner/installimage-proxmox.sh host.example.com
```

### Hardening (opt-in)

Five roles are shipped switched off, because turning them on changes how the
host behaves and two of them can lock you out. Enable them deliberately:

```yaml
# inventory/group_vars/all.yml
proxmox_ssh_manage: "yes"           # keys instead of passwords
proxmox_updates_manage: "yes"       # unattended security updates
proxmox_firewall_manage: "yes"      # pve-firewall
proxmox_firewall_enable: true
proxmox_firewall_management_networks: ["203.0.113.0/24"]
proxmox_notifications_manage: "yes"
proxmox_notifications_email: "alerts@example.com"
proxmox_backup_manage: "yes"
```

Both risky ones refuse to shoot you in the foot:

- `proxmox_ssh` will not disable password logins when root has no
  `authorized_keys`, and runs `sshd -t` before anything is restarted.
- `proxmox_firewall` will not enable the firewall if the address you are
  connected from is outside the management networks you listed.

Run them with `--check --diff` first, and keep a console open.

```bash
ansible-playbook playbooks/proxmox.yml --tags security --check --diff
ansible-playbook playbooks/proxmox.yml --tags security
```

`proxmox_notifications` covers the part people notice only when it is missing:
ZED mails on a degraded pool, smartd mails on a failing disk, root's mail goes
to a real address, and `root@pam` gets that address in Proxmox.
`proxmox_backup` attaches a Proxmox Backup Server, creates a vzdump job, and by
default fails the play on a host that has no backup job at all.

### Tinc VPN Mesh Setup

Mesh VPN between nodes, for corosync and Ceph traffic. Config lands in
`/etc/tinc/pvemesh`, the unit is `tinc-pvemesh.service`.

Cipher and digest are pinned (`aes-256-cbc` / `sha256`) and compression is off.
All nodes must agree on those values. Tinc 1.0 has no forward secrecy, so for a
new deployment WireGuard is the better choice.

```bash
# Configure inventory (hosts.ini itself is git-ignored) with per-host variables
# inventory/hosts.ini:
# [proxmox]
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

- [ansible/README.md](ansible/README.md) - roles, variables, secrets
- [ansible/playbooks/README.md](ansible/playbooks/README.md) - playbook reference
- [CHANGELOG.md](CHANGELOG.md) - what changed and what breaks

## 💡 Features

The post-installation script (`install-post.sh`) transforms your Proxmox host with:

<table>
<tr>
<td width="50%">

### 🔒 Security Hardening
- ✅ Fail2ban for the web interface (journald backend, pvedaemon + pveproxy)
- ✅ Disable portmapper/rpcbind
- ✅ Lynis security scan tool
- ✅ Kernel panic auto-reboot
- ✅ Core dumps off by default
- ✅ Network security sysctls

### ⚡ Performance Tuning
- ✅ TCP BBR congestion control
- ✅ TCP FastOpen enabled
- ✅ Memory reserve scaled to RAM size
- ✅ ZFS ARC size auto-tuning
- ✅ Vzdump backup speed increase
- ✅ Pigz (parallel gzip) via dpkg-divert

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
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/install-post.sh -O install-post.sh
# verify against the published SHA256SUMS before running - see Quick Start
bash install-post.sh
```

#### Custom Configuration

Create a configuration file for custom options:

```bash
# Download sample configuration
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/install-post.env.sample -O install-post.env

# Edit configuration
nano install-post.env

# Run with custom settings
bash install-post.sh
```

The env file is only sourced when it is owned by root, not group- or
world-writable, not a symlink, and sitting in a directory that is itself owned
by root and not writable by anyone else. Otherwise it is skipped with a warning,
since sourcing it means executing it as root.

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
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/debian-2-proxmox/debian13-2-proxmox9.sh
chmod +x debian13-2-proxmox9.sh
./debian13-2-proxmox9.sh
```

#### Debian 12 → Proxmox VE 8
```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/debian-2-proxmox/debian12-2-proxmox8.sh
chmod +x debian12-2-proxmox8.sh
./debian12-2-proxmox8.sh
```

**Note:** the conversion scripts look for `install-post.sh` next to themselves
first. To let them download it instead, set `XS_ALLOW_REMOTE_INSTALL_POST=yes`
and `XS_INSTALL_POST_SHA256=<expected_sha256>`.

They no longer create an `admin@pve` account by default. If you want one, set
`XS_CREATE_ADMIN_USER=yes` and pass `XS_ADMIN_PASSWORD` for unattended runs.

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
# From the Hetzner rescue system
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/hetzner/vnc-install-proxmox.sh
chmod +x vnc-install-proxmox.sh

# ISO checksum from https://www.proxmox.com/en/downloads
export MY_PVE_ISO_SHA256="..."

# Proxmox VE 8 (default) / VE 9 / Backup Server
INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh
INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh pve9
INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh pbs
```

The installer's VNC server listens on loopback only. Reach it with
`ssh -N -L 5900:127.0.0.1:5900 root@<rescue-ip>` and connect to
`localhost:5900`. VNC authentication only uses the first 8 characters of the
password, which is why it is not exposed directly.

#### Installimage Automated Installation
```bash
# From Hetzner Rescue System
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/hetzner/installimage-proxmox.sh -O installimage-proxmox.sh
chmod +x installimage-proxmox.sh

# Checksum of hetzner/pve (or hetzner/pbs), which runs inside the chroot
export MY_POSTINSTALL_SHA256="..."

# Proxmox VE 8 / VE 9 / Backup Server
INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn"
INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn" pve9
INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn" pbs
```

Both installers wipe the partition table of the install target by default. They
print the disks with model and serial and wait 10 seconds before doing it.

### OVH Installation

Detailed guide for OVH dedicated servers: [📖 OVH README](ovh/README.md)

**Quick Setup:**
1. Select **Install from OVH template** → **VPS Proxmox VE**
2. Configure partitions (see guide for recommended layout)
3. Set installation script URL: `https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/install-post.sh`
4. After installation, run LVM to ZFS conversion and networking scripts

---

## 💾 ZFS Management

### LVM to ZFS Conversion

Convert MDADM-based LVM to ZFS with automatic RAID level detection.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/lvm-2-zfs.sh -O lvm-2-zfs.sh
chmod +x lvm-2-zfs.sh
LVM2ZFS_CONFIRM=yes ./lvm-2-zfs.sh [LVM_MOUNT_POINT]
```

**Creates:**
- `zfsbackup` (rpool/backup)
- `zfsvmdata` (rpool/vmdata)
- `/var/lib/vz/tmp_backup` (rpool/tmp_backup)

### Create ZFS Pool

Create ZFS pool from specified devices with automatic RAID detection.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/createzfs.sh -O createzfs.sh
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
| 6-11 | raidz-2 | RAID6 |
| 12+ | raidz-3 | RAID7 |

### ZFS Cache and SLOG

Add L2ARC cache and SLOG to existing ZFS pool.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/slog-cache-2-zfs.sh -O slog-cache-2-zfs.sh
chmod +x slog-cache-2-zfs.sh
./slog-cache-2-zfs.sh poolname
```

It looks for MD arrays mounted at `/ashimov/zfs-cache` and `/ashimov/zfs-slog`,
which is where the Hetzner installimage script puts them. The pool must exist
already.

### ZFS Benchmark

Test ZFS performance with various write patterns.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/benchmark_zfs.sh -O benchmark_zfs.sh
chmod +x benchmark_zfs.sh
cd /path/to/zfs/dataset && ./benchmark_zfs.sh
```

Writes about 20 GB into the current directory and cleans up afterwards.

---

## 🔌 Networking

### Network Configuration

Create routed vmbr0 network bridge for Proxmox VMs.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/networking/network-configure.sh -O network-configure.sh
chmod +x network-configure.sh
./network-configure.sh
```

**Features:**

- **vmbr0 (Routed):** Public IPs routed through physical interface
- Auto-detects interface, gateway, and netmask
- Supports IPv4 and IPv6
- Saves the old file as `/etc/network/interfaces.<timestamp>`

The new config applies on reboot or `ifreload -a`. Read it before restarting
networking, and keep a console open in case the detection guessed wrong.

### Tinc VPN

Create private mesh VPN for cluster communication with multicast support.

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/networking/tincvpn.sh -O tincvpn.sh
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
curl https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/helpers/pve-enable-lxc-docker.sh --output /usr/sbin/pve-enable-lxc-docker
chmod +x /usr/sbin/pve-enable-lxc-docker
LXC_DOCKER_CONFIRM=yes pve-enable-lxc-docker <container_id>
```

It switches off AppArmor for that container, allows every device, drops no
capabilities and mounts `/proc` and `/sys` read-write, then restarts it. On a
shared host that is not an acceptable trade.

> 💡 **Recommendation:** Use a dedicated VM for Docker instead of LXC containers.

---

## 📝 Additional Notes

### Recommended Partitioning Scheme

| Partition | Size | Filesystem | Mount Point |
|-----------|------|------------|-------------|
| Root | 40 GB | ext4 (RAID1) | / |
| ZFS Cache* | 30 GB | ext4 (RAID1) | /ashimov/zfs-cache |
| ZFS SLOG* | 5 GB | ext4 (RAID1) | /ashimov/zfs-slog |
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

Every release ships a `SHA256SUMS` covering all the scripts, signed with cosign
keyless so the list itself can be checked:

```bash
RELEASE=v1.0.4
BASE="https://github.com/ashimov/proxmox-optimizer/releases/download/${RELEASE}"
wget "${BASE}/SHA256SUMS" "${BASE}/SHA256SUMS.sig" "${BASE}/SHA256SUMS.pem"

# optional but recommended: is this checksum list actually ours?
cosign verify-blob \
  --certificate SHA256SUMS.pem \
  --signature SHA256SUMS.sig \
  --certificate-identity-regexp '^https://github.com/ashimov/proxmox-optimizer/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS

# then the scripts you downloaded
sha256sum --ignore-missing -c SHA256SUMS
```

`scripts/make-checksums.sh` produces the same list locally if you want to
compare against a checkout.

### Environment Variables for Checksum Verification

Shell scripts:

| Script | Checksum Variable | Allow Unverified Variable |
|--------|-------------------|---------------------------|
| `install-post.sh` (remote download) | `XS_INSTALL_POST_SHA256` | `XS_ALLOW_REMOTE_INSTALL_POST` |
| OVH RTM installer | `XS_OVHRTM_SHA256` | `XS_OVHRTM_ALLOW_UNVERIFIED` |
| Proxmox APT signing key | `XS_PROXMOX_KEY_SHA256` | *(warns when empty)* |
| Cisofy/Lynis APT signing key | `XS_CISOFY_KEY_SHA256` | *(warns when empty)* |
| PVE edge kernel `.deb` | `PVE_EDGE_KERNEL_SHA256` | `PVE_EDGE_KERNEL_ALLOW_UNVERIFIED` |
| NVIDIA container toolkit key | `NVIDIA_TOOLKIT_GPG_SHA256` | *(warns when empty)* |
| NVIDIA container toolkit repo list | `NVIDIA_TOOLKIT_LIST_SHA256` | *(warns when empty)* |
| Hetzner `installimage` post-install | `MY_POSTINSTALL_SHA256` | `MY_POSTINSTALL_ALLOW_UNVERIFIED` |
| Hetzner VNC: Proxmox VE ISO | `MY_PVE_ISO_SHA256` | `MY_ISO_ALLOW_UNVERIFIED` |
| Hetzner VNC: Proxmox Backup Server ISO | `MY_PBS_ISO_SHA256` | `MY_ISO_ALLOW_UNVERIFIED` |

Ansible role variables (set in `inventory/group_vars/all.yml` or `host_vars`):

| Role | Variable | Purpose |
|------|----------|---------|
| `proxmox_security` | `xs_lynis_key_url` | Override the CISofy signing-key URL (defaults to upstream) |
| `proxmox_security` | `xs_lynis_key_sha256` | Pinned SHA256 of the Lynis signing key (empty = TLS only, warns at runtime) |
| `proxmox_nvidia` | `nvidia_toolkit_gpg_sha256` | Pinned SHA256 of the NVIDIA container toolkit signing key |
| `proxmox_nvidia` | `nvidia_toolkit_list_sha256` | Pinned SHA256 of `nvidia-container-toolkit.list` |
| `proxmox_base` | `proxmox_key_checksums` | Per-codename SHA256 of the Proxmox release key |

### Example: Secure Remote Installation

```bash
# Set the expected SHA256 checksum (get from releases or compute yourself)
export XS_INSTALL_POST_SHA256="your_checksum_here"
export XS_ALLOW_REMOTE_INSTALL_POST="yes"

# Run the conversion script - it will verify the checksum before execution
./debian12-2-proxmox8.sh
```

```bash
# Hetzner VNC installer: verify the ISO before booting it, confirm explicitly,
# and reach the installer console over an SSH tunnel (the VNC server is bound
# to loopback because VNC auth only uses the first 8 password characters).
export MY_PVE_ISO_SHA256="<sha256 from https://www.proxmox.com/en/downloads>"
INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh pve9

# from your workstation:
ssh -N -L 5900:127.0.0.1:5900 root@<rescue-ip>
# then point the VNC client at localhost:5900
```

### Other Safety Knobs

| Variable | Default | Effect |
|----------|---------|--------|
| `XS_CEPH_FAIL_HARD` | `no` | If `yes`, `install-post.sh` aborts when `pveceph install` fails or times out instead of just logging a warning. Recommended for unattended installs. |
| `XS_COREDUMP` | `no` | Core dumps are disabled by default: a dump of a Proxmox daemon contains cluster keys and auth tickets in cleartext. Set to `yes` only while debugging. |
| `XS_HUGEPAGES` | *(empty)* | Number of hugepages to preallocate. Empty means none - preallocated hugepages are locked away from normal allocation. |
| `INSTALL_CONFIRM` | `no` | Required by both Hetzner installers before they touch a disk. |
| `MY_VNC_BIND` | `127.0.0.1` | Address the VNC installer binds to. Keep it on loopback and use an SSH tunnel: VNC authentication only uses the first 8 characters of the password. |
| `XS_CREATE_ADMIN_USER` | `no` | Whether the Debian to Proxmox converters create an `admin@pve` Administrator account. When `yes`, `XS_ADMIN_PASSWORD` must be set for non-interactive runs. |
| `LVM2ZFS_CONFIRM` / `ZFS_CONFIRM` | `no` | Required by the destructive ZFS scripts. `ZFS_DRYRUN=yes` prints what would happen instead. |

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
