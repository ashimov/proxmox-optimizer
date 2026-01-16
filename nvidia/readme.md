# 🎮 NVIDIA GPU Support for Proxmox

> Initial work by @88plug

## Overview

Scripts and instructions for enabling NVIDIA GPU support on Proxmox VE hosts, including Docker integration.

> **Recommended:** Use Ansible roles for repeatable, idempotent deployments.
> See [ansible/README.md](../ansible/README.md) for details.

## Ansible Role

| Role | Description | Playbook |
|------|-------------|----------|
| `proxmox_nvidia` | NVIDIA Docker runtime for GPU passthrough | `playbooks/nvidia-docker.yml` |

### Ansible Usage

```bash
cd ansible

# Install NVIDIA Docker runtime
ansible-playbook playbooks/nvidia-docker.yml -i inventory/hosts.ini

# Skip reboot
ansible-playbook playbooks/nvidia-docker.yml -i inventory/hosts.ini -e nvidia_docker_reboot=false
```

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
NVIDIA_DOCKER_REBOOT=no ./nvidia-docker.sh
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

### Fan Control Example

> **Note:** Replace `121` with your actual user ID from `/run/user/`.

```bash
# Set fan speed to 80-85% for GPUs 0-3
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority \
  sudo nvidia-settings -a [gpu:0]/GPUFanControlState=1 -a [fan-0]/GPUTargetFanSpeed=80

DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority \
  sudo nvidia-settings -a [gpu:1]/GPUFanControlState=1 -a [fan-1]/GPUTargetFanSpeed=80
```

### Overclocking Example

```bash
# Set clock offset +150 and memory offset +600 for GPU 0
DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority \
  nvidia-settings -a '[gpu:0]/GPUGraphicsClockOffset[3]=150'

DISPLAY=:0 XAUTHORITY=/run/user/121/gdm/Xauthority \
  nvidia-settings -a '[gpu:0]/GPUMemoryTransferRateOffset[3]=600'
```

---

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
