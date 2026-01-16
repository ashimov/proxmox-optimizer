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

### Installation Commands

```bash
# Download script
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/hetzner/vnc-install-proxmox.sh
chmod +x vnc-install-proxmox.sh
```

| Platform | Command |
|----------|---------|
| **Proxmox VE 8** (default) | `./vnc-install-proxmox.sh` |
| **Proxmox VE 9** | `./vnc-install-proxmox.sh pve9` |
| **Proxmox Backup Server** | `./vnc-install-proxmox.sh pbs` |

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
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/hetzner/installimage-proxmox.sh -c -O installimage-proxmox.sh
chmod +x installimage-proxmox.sh
```

| Platform | Command |
|----------|---------|
| **Proxmox VE 8** | `./installimage-proxmox.sh "your.hostname.fqdn"` |
| **Proxmox VE 9** | `./installimage-proxmox.sh "your.hostname.fqdn" pve9` |
| **Proxmox Backup Server** | `./installimage-proxmox.sh "your.hostname.fqdn" pbs` |

#### Step 4: Reboot

```bash
reboot
```

---

## 🔧 Post-Installation Steps

After installation, connect via SSH to your new Proxmox system.

### 1. LVM to ZFS Conversion (Optional)

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/lvm-2-zfs.sh -c -O lvm-2-zfs.sh
chmod +x lvm-2-zfs.sh
./lvm-2-zfs.sh && rm lvm-2-zfs.sh
# REBOOT
```

### 2. Network Configuration (vmbr0)

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/networking/network-configure.sh -c -O network-configure.sh
chmod +x network-configure.sh
./network-configure.sh && rm network-configure.sh
# REBOOT
```

### 3. Post-Install Optimization (Optional)

*Skip if using installimage method (already included)*

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh -c -O install-post.sh
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
