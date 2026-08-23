# 🎮 NVIDIA GPU Support for Proxmox

> Initial work by @88plug

## Overview

Scripts and instructions for enabling NVIDIA GPU support on Proxmox VE hosts,
including Docker integration through the NVIDIA Container Toolkit.

Note that running the GPU on the hypervisor itself and passing it through to a
VM are mutually exclusive. If you want VFIO passthrough, do not install the
driver on the host.

> **Recommended:** Use Ansible roles for repeatable, idempotent deployments.
> See [ansible/README.md](../ansible/README.md) for details.

## Ansible Role

| Role | Description | Playbook |
|------|-------------|----------|
| `proxmox_nvidia` | NVIDIA Container Toolkit for Docker | `playbooks/nvidia-docker.yml` |

### Ansible Usage

```bash
cd ansible

# Install the container toolkit and wire it into Docker
ansible-playbook playbooks/nvidia-docker.yml

# Reboot afterwards (off by default)
ansible-playbook playbooks/nvidia-docker.yml -e nvidia_docker_reboot=true
```

| Variable | Default | Description |
|----------|---------|-------------|
| `nvidia_docker_enabled` | `true` | Set to false to skip the role |
| `nvidia_docker_reboot` | `false` | Reboot after installation |
| `nvidia_configure_docker_runtime` | `true` | Run `nvidia-ctk runtime configure --runtime=docker` |
| `nvidia_toolkit_gpg_sha256` | empty | Pinned checksum of the signing key |
| `nvidia_toolkit_list_sha256` | empty | Pinned checksum of the repo list file |

## Prerequisites

```bash
apt-get install build-essential pve-headers-$(uname -r) pkg-config libgtk-3-0 libglvnd-dev xserver-xorg-dev dkms
update-grub
# REBOOT
```

## Installation Steps

### 1. Download NVIDIA Driver

Pick the current version from
[nvidia.com/drivers](https://www.nvidia.com/en-us/drivers/unix/) - the example
below is only the shape of the command, not a version recommendation.

```bash
VER=550.127.05
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/${VER}/NVIDIA-Linux-x86_64-${VER}.run
chmod +x NVIDIA-Linux-x86_64-${VER}.run
./NVIDIA-Linux-x86_64-${VER}.run
```

The driver has to be rebuilt after every kernel upgrade unless you install it
with DKMS.

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
| `nvidia-docker.sh` | Installs `nvidia-container-toolkit` and reloads Docker |

The old `nvidia-docker2` package and the `nvidia.github.io/nvidia-docker`
repository are end of life and publish nothing for Debian 12/13. The script uses
the `libnvidia-container` repository instead, which is not per-distribution, and
removes the old repo file if a previous run added it.

```bash
# no reboot (default)
./nvidia-docker.sh

# with a pinned key checksum
NVIDIA_TOOLKIT_GPG_SHA256=<sha256> ./nvidia-docker.sh

# reboot when done
NVIDIA_DOCKER_REBOOT=yes ./nvidia-docker.sh
```

### Fan Control Example

> Replace `121` with the actual user ID from `/run/user/`. These commands need
> an X session, which a headless Proxmox host does not normally have.

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
