# Helper Scripts

## Overview

Collection of helper scripts for various Proxmox VE tasks.

> **Recommended:** Use Ansible roles for repeatable, idempotent deployments.
> See [ansible/README.md](../ansible/README.md) for details.

## Ansible Roles

| Role | Description | Playbook |
|------|-------------|----------|
| `proxmox_lxc_docker` | Docker support for LXC containers | `playbooks/lxc-docker.yml` |
| `proxmox_nvidia` | NVIDIA Docker runtime | `playbooks/nvidia-docker.yml` |

### Ansible Usage

```bash
cd ansible

# Docker in LXC (requires explicit confirmation)
ansible-playbook playbooks/lxc-docker.yml \
  -e lxc_docker_container_id=100 \
  -e lxc_docker_confirm=true

# NVIDIA Docker runtime
ansible-playbook playbooks/nvidia-docker.yml
```

## Shell Scripts

| Script | Description |
|--------|-------------|
| `pve-enable-lxc-docker.sh` | Enables Docker support in LXC containers |
| `pve-edege-kernel.sh` | Installs PVE Edge Kernel (experimental) |

---

## pve-enable-lxc-docker.sh

Configures an LXC container to properly support Docker.

### Security Warning

Running Docker inside LXC containers requires elevated privileges and may have security implications. The container runs in a higher privileged mode.

> **Recommendation:** Use a dedicated VM (QEMU/KVM) for Docker instead of LXC containers.

### Usage

```bash
# Requires explicit confirmation
LXC_DOCKER_CONFIRM=yes pve-enable-lxc-docker <container_id>
```

### Installation

```bash
curl https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/helpers/pve-enable-lxc-docker.sh \
  --output /usr/sbin/pve-enable-lxc-docker
chmod +x /usr/sbin/pve-enable-lxc-docker
```

### What it does

Adds the following to the container configuration:

- `lxc.apparmor.profile: unconfined`
- `lxc.cgroup.devices.allow: a`
- `lxc.cap.drop:` (empty)
- `linux.kernel_modules: aufs ip_tables`
- `lxc.mount.auto: proc:rw sys:rw`

---

## pve-edege-kernel.sh

Installs the PVE Edge Kernel for experimental features.

### Experimental

This kernel is for testing purposes. Use at your own risk in production environments.

> **Note:** The default URL points to an older kernel version (5.11.0-2).
> Check [pve-edge-kernel releases](https://github.com/fabianishere/pve-edge-kernel/releases) for newer versions.

### Usage

```bash
# With checksum verification (recommended)
PVE_EDGE_KERNEL_SHA256="your_checksum" ./pve-edege-kernel.sh

# With custom URL
PVE_EDGE_KERNEL_URL="https://github.com/.../newer-kernel.deb" \
PVE_EDGE_KERNEL_SHA256="checksum" ./pve-edege-kernel.sh

# Without verification (not recommended)
PVE_EDGE_KERNEL_ALLOW_UNVERIFIED=yes ./pve-edege-kernel.sh
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `PVE_EDGE_KERNEL_URL` | Custom kernel .deb URL |
| `PVE_EDGE_KERNEL_SHA256` | Expected SHA256 checksum |
| `PVE_EDGE_KERNEL_ALLOW_UNVERIFIED` | Set to `yes` to skip verification |

---

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
