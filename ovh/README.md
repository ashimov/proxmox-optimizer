# 🏢 OVH Proxmox Installation Guide

<div align="center">

[![OVH](https://img.shields.io/badge/Provider-OVH-0050D8.svg)](https://www.ovh.com/)
[![Proxmox VE](https://img.shields.io/badge/Proxmox%20VE-8.x-green.svg)](https://www.proxmox.com/)

*Professional installation guide for OVH dedicated servers*

</div>

---

## 📋 Installation via OVH Manager

### Step 1: Start Installation

1. Select the server in OVH Manager
2. Click **INSTALL** → **Install from an OVH template**
3. Click **NEXT**

### Step 2: Select OS

| Option | Value |
|--------|-------|
| Type of OS | **Ready-to-go (graphical user interface)** |
| Template | **VPS Proxmox VE** *(pick latest non-ZFS version)* |
| Language | **EN** |
| Target disk array | *(Select SSD array if you have both SSD and HDD)* |
| Customise partitions | ✅ **Enable** |

### Step 3: Configure Partitions

| # | Type | Filesystem | Mount Point | LVM Name | RAID | Size |
|---|------|------------|-------------|----------|------|------|
| 1 | primary | Ext4 | / | - | 1 | 20.0 GB |
| 2 | primary | Swap | swap | - | - | 2 × 8.0 GB* |
| 3 | LV | xfs | /var/lib/vz | data | 1 | REMAINING |

> *Recommended minimum 16GB total swap

### Step 4: Complete Installation

| Option | Value |
|--------|-------|
| Hostname | `server.fqdn.com` |
| Installation script | `https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh` |
| Script return value | `0` |
| SSH keys | *(optional but recommended)* |

Click **CONFIRM** to start installation.

---

## 🔧 Post-Installation Steps

After installation, connect via SSH to your Proxmox server.

### 1. LVM to ZFS Conversion

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/lvm-2-zfs.sh -c -O lvm-2-zfs.sh
chmod +x lvm-2-zfs.sh
./lvm-2-zfs.sh && rm lvm-2-zfs.sh
# REBOOT
```

### 2. Network Configuration (vmbr0 + vmbr1)

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/networking/network-configure.sh -c -O network-configure.sh
chmod +x network-configure.sh
./network-configure.sh && rm network-configure.sh
# REBOOT
```

### 3. Set Root Password

Login via SSH and set a password for web interface access:

```bash
passwd root
```

---

## 🚀 Advanced Installation

For setups with SSD raid1 partitions mounted as `/xshok/zfs-slog` and `/xshok/zfs-cache` with unused HDDs.

### Create ZFS from Unused Devices

⚠️ **WARNING: DESTROYS ALL DATA ON SPECIFIED DEVICES**

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/createzfs.sh -c -O createzfs.sh
chmod +x createzfs.sh
./createzfs.sh poolname /dev/device1 /dev/device2
```

### Add ZFS Cache and SLOG

⚠️ **WARNING: DESTROYS ALL DATA ON SPECIFIED PARTITIONS**

```bash
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/slog-cache-2-zfs.sh -c -O slog-cache-2-zfs.sh
chmod +x slog-cache-2-zfs.sh
./slog-cache-2-zfs.sh poolname
# REBOOT
```

---

## 📋 Recommended Partition Layout

For SSD + HDD configurations:

| Partition | Filesystem | Mount Point | Size | Notes |
|-----------|------------|-------------|------|-------|
| Root | ext4 (RAID1) | / | 20-40 GB | SSD |
| ZFS Cache | ext4 (RAID1) | /xshok/zfs-cache | 30 GB | SSD |
| ZFS SLOG | ext4 (RAID1) | /xshok/zfs-slog | 5 GB | SSD |
| Swap | swap | - | 16-64 GB | Based on RAM |
| Data | xfs (LVM) | /var/lib/vz | Remaining | HDD pool |

---

<div align="center">

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*

</div>
