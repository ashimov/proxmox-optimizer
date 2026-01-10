# 🎮 NVIDIA GPU Support for Proxmox

> Initial work by @88plug

## Overview

Scripts and instructions for enabling NVIDIA GPU support on Proxmox VE hosts, including Docker integration.

## Prerequisites

```bash
apt-get install build-essential pve-headers-$(uname -r) pkg-config libgtk-3-0 libglvnd-dev xserver-xorg-dev dkms
update-grub
# REBOOT
```

## Installation Steps

### 1. Download NVIDIA Driver

```bash
# Get the latest driver from NVIDIA
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/460.56/NVIDIA-Linux-x86_64-460.56.run
chmod +x NVIDIA-Linux-x86_64-460.56.run
./NVIDIA-Linux-x86_64-460.56.run
```

### 2. Installer Prompts

| Prompt | Response |
|--------|----------|
| Create modprobe file | **YES** |
| 32-bit dependencies | **YES** |
| Update X configuration | **NO** |

### 3. Reboot and Verify

```bash
reboot
nvidia-smi
```

## Docker Integration

After GPU driver installation, install nvidia-docker:

```bash
./nvidia-docker.sh
```

## Advanced Configuration

### Unlock Power/Clock Controls

```bash
sudo nvidia-xconfig -a --cool-bits=31 --allow-empty-initial-configuration
nvidia-smi -pl 200 -i 0
```

### Overclocking Requirements

For overclocking, you need X authority/GDM:

```bash
# Install GNOME desktop
tasksel  # Select GNOME desktop

# Disable sleep (GNOME enables it by default)
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Reboot - Xauthority will be at:
# /run/user/$SOMENUMBER/gdm/Xauthority
```

## Scripts

| Script | Description |
|--------|-------------|
| `nvidia-docker.sh` | Installs nvidia-docker2 for GPU container support |

---
*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*


replace $SOMENUBMER in lines below! :)

DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority sudo nvidia-settings -a [gpu:0]/GPUFanControlState=1 -a [fan-0]/GPUTargetFanSpeed=80
sleep 3
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority sudo nvidia-settings -a [gpu:1]/GPUFanControlState=1 -a [fan-1]/GPUTargetFanSpeed=80
sleep 3
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority sudo nvidia-settings -a [gpu:2]/GPUFanControlState=1 -a [fan-2]/GPUTargetFanSpeed=80
sleep 3
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority sudo nvidia-settings -a [gpu:3]/GPUFanControlState=1 -a [fan-3]/GPUTargetFanSpeed=85

DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:0]/GPUGraphicsClockOffset[3]=150'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:0]/GPUMemoryTransferRateOffset[3]=600'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:1]/GPUGraphicsClockOffset[3]=150'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:1]/GPUMemoryTransferRateOffset[3]=600'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:2]/GPUGraphicsClockOffset[3]=150'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:2]/GPUMemoryTransferRateOffset[3]=600'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:3]/GPUGraphicsClockOffset[3]=150'
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority nvidia-settings -a '[gpu:3]/GPUMemoryTransferRateOffset[3]=600'
