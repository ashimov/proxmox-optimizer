# 🛠️ Helper Scripts

## Overview

Collection of helper scripts for various Proxmox VE tasks.

## Scripts

| Script | Description |
|--------|-------------|
| `pve-enable-lxc-docker.sh` | Enables Docker support in LXC containers |
| `pve-edege-kernel.sh` | Installs PVE Edge Kernel (experimental) |

---

## pve-enable-lxc-docker.sh

Configures an LXC container to properly support Docker.

### ⚠️ Security Warning

Running Docker inside LXC containers requires elevated privileges and may have security implications. The container runs in a higher privileged mode.

> **Recommendation:** Use a dedicated VM (QEMU/KVM) for Docker instead of LXC containers.

### Usage

```bash
# Install the script
curl https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/helpers/pve-enable-lxc-docker.sh \
  --output /usr/sbin/pve-enable-lxc-docker
chmod +x /usr/sbin/pve-enable-lxc-docker

# Enable Docker for a container
pve-enable-lxc-docker <container_id>
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

### ⚠️ Experimental

This kernel is for testing purposes. Use at your own risk in production environments.

### Usage

```bash
./pve-edege-kernel.sh
```

---

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
