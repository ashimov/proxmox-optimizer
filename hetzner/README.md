# 🏢 Hetzner Proxmox Installation Guide

<div align="center">

[![Hetzner](https://img.shields.io/badge/Provider-Hetzner-red.svg)](https://www.hetzner.com/)
[![Proxmox VE 9.x](https://img.shields.io/badge/Proxmox%20VE-9.x-orange.svg)](https://www.proxmox.com/)
[![Proxmox VE 8.x](https://img.shields.io/badge/Proxmox%20VE-8.x-green.svg)](https://www.proxmox.com/)
[![PBS 3.x](https://img.shields.io/badge/PBS-3.x-purple.svg)](https://www.proxmox.com/)

*Professional installation scripts for Hetzner dedicated servers*

</div>

---

## 📋 Supported Platforms

| Platform | Version | Status |
|----------|---------|--------|
| Proxmox VE | 9.x | ✅ Supported |
| Proxmox VE | 8.x | ✅ Supported |
| Proxmox Backup Server | 3.x | ✅ Supported |

## ⚙️ Prerequisites

Run these scripts from the **Hetzner Rescue System**:
- Operating system: **Linux**
- Architecture: **64 bit**
- Public key: *optional*

> 💡 Scripts automatically detect NVMe, SSD, and HDD and configure accordingly.

---

## 🖥️ Method 1: VNC Installation (Native ISO)

Native Proxmox installation from ISO on systems without IPMI.

### Features
- Automatically detects NVMe, SSD, and HDD
- SATA SSD used for boot/root instead of NVMe
- Uses NVMe if sda is a spinning disk

### Before you run it

The script boots the Proxmox ISO in QEMU against your real disks, so it wants
two things from you:

- `MY_PVE_ISO_SHA256` (or `MY_PBS_ISO_SHA256`) from the
  [Proxmox downloads page](https://www.proxmox.com/en/downloads). Without it the
  script refuses to boot the ISO.
- `INSTALL_CONFIRM=yes`. With `WIPE_PARTITION_TABLE=TRUE` (the default) it
  writes a fresh GPT label on the install target, which throws away every
  partition on it. The script prints the disks with model and serial and waits
  10 seconds first.

### Installation Commands

```bash
# Download script
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/hetzner/vnc-install-proxmox.sh
chmod +x vnc-install-proxmox.sh

export MY_PVE_ISO_SHA256="<sha256 from the Proxmox downloads page>"
```

| Platform | Command |
|----------|---------|
| **Proxmox VE 8** (default) | `INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh` |
| **Proxmox VE 9** | `INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh pve9` |
| **Proxmox Backup Server** | `INSTALL_CONFIRM=yes ./vnc-install-proxmox.sh pbs` |

### Reaching the installer

The VNC server listens on `127.0.0.1:5900` only. VNC authentication uses just
the first 8 characters of the password, and the rescue system sits on a public
IP with no firewall, so it is not something to expose. Tunnel to it:

```bash
ssh -N -L 5900:127.0.0.1:5900 root@<rescue-ip>
# then point your VNC client at localhost:5900
```

The password is printed by the script. If you really need a direct bind, set
`MY_VNC_BIND=0.0.0.0` and understand what you are getting.

### Useful variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INSTALL_CONFIRM` | `no` | Must be `yes` before anything touches a disk |
| `MY_PVE_ISO_SHA256` / `MY_PBS_ISO_SHA256` | empty | Expected ISO checksum |
| `MY_ISO_ALLOW_UNVERIFIED` | `no` | Skip the checksum check (don't) |
| `MY_PVE_ISO_VERSION` | `8.3-1` / `9.0-1` | ISO version to download |
| `MY_VNC_BIND` | `127.0.0.1` | VNC listen address |
| `WIPE_PARTITION_TABLE` | `TRUE` | Write a new GPT label on the target |
| `NVME_FORCE_4K` | `FALSE` | Reformat NVMe to 4K LBA before installing |

---

## 🤖 Method 2: Automated Installimage

Fully automated installation using Hetzner's installimage.

### Features
- ext3 boot partition (1GB)
- ext4 root partition (up to 128GB)
- SATA SSD used for boot/root instead of NVMe
- SLOG and L2ARC auto-configured
- Includes post-installation optimization

### Step-by-Step Installation

#### Step 1: Activate Rescue System

1. Go to **Hetzner Robot Manager**
2. Select the **Rescue** tab for your server
3. Configure:
   - Operating system: **Linux**
   - Architecture: **64 bit**
   - Public key: *optional*
4. Click **Activate rescue system**

#### Step 2: Reset Server

1. Select the **Reset** tab
2. Check: **Execute an automatic hardware reset**
3. Click **Send**

#### Step 3: Connect and Install

Wait a few minutes, then connect via SSH:

```bash
# Download script
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/hetzner/installimage-proxmox.sh -O installimage-proxmox.sh
chmod +x installimage-proxmox.sh
```

| Platform | Command |
|----------|---------|
| **Proxmox VE 8** | `INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn"` |
| **Proxmox VE 9** | `INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn" pve9` |
| **Proxmox Backup Server** | `INSTALL_CONFIRM=yes ./installimage-proxmox.sh "your.hostname.fqdn" pbs` |

The script downloads its post-install file (`hetzner/pve` or `hetzner/pbs`) from
GitHub and runs it inside the chroot as root, so it wants the checksum:

```bash
export MY_POSTINSTALL_SHA256="<sha256 of hetzner/pve>"
```

Without it the run stops, unless you set `MY_POSTINSTALL_ALLOW_UNVERIFIED=true`.

Partition layout knobs: `MY_BOOT`, `MY_ROOT`, `MY_SWAP`, `MY_ZFS_SLOG`,
`MY_ZFS_L2ARC` (all in GB, blank means auto). SLOG and cache partitions are
mounted at `/ashimov/zfs-slog` and `/ashimov/zfs-cache`, which is what
`zfs/slog-cache-2-zfs.sh` looks for afterwards.

#### Step 4: Reboot

```bash
reboot
```

---

## 🔧 Post-Installation Steps

After installation, connect via SSH to your new Proxmox system.

### 1. LVM to ZFS Conversion (Optional)

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/lvm-2-zfs.sh -O lvm-2-zfs.sh
chmod +x lvm-2-zfs.sh
LVM2ZFS_CONFIRM=yes ./lvm-2-zfs.sh && rm lvm-2-zfs.sh
# REBOOT
```

This destroys `/var/lib/vz`. Back it up first.

### 2. Network Configuration (vmbr0)

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/networking/network-configure.sh -O network-configure.sh
chmod +x network-configure.sh
./network-configure.sh && rm network-configure.sh
# REBOOT
```

### 3. Post-Install Optimization (Optional)

*Skip if using installimage method (already included)*

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/install-post.sh -O install-post.sh
# verify against the release SHA256SUMS before running
chmod +x install-post.sh
./install-post.sh && rm install-post.sh
```

---

## 🔐 Final Steps

Login via SSH as root and set a password for web interface access (PAM authentication):

```bash
passwd root
```

---

## 📁 Scripts in this Folder

| File | Description |
|------|-------------|
| `installimage-proxmox.sh` | Automated installation via Hetzner installimage |
| `vnc-install-proxmox.sh` | VNC-based native ISO installation |
| `pve` | Proxmox VE configuration template |
| `pbs` | Proxmox Backup Server configuration template |

---

<div align="center">

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*

</div>
