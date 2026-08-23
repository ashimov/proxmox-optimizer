# ZFS Management Scripts

## Overview

Collection of ZFS management scripts for Proxmox VE.

> **Recommended:** Use Ansible roles for repeatable, idempotent deployments.
> See [ansible/README.md](../ansible/README.md) for details.

## Ansible Roles

| Role | Description | Playbook |
|------|-------------|----------|
| `proxmox_zfs` | ZFS ARC tuning and auto-snapshots | `playbooks/proxmox.yml` |
| `proxmox_zfs_convert` | LVM to ZFS conversion | `playbooks/lvm-to-zfs.yml` |
| `proxmox_zfs_create` | ZFS pool creation | `playbooks/zfs-create.yml` |
| `proxmox_zfs_slog_cache` | MD RAID to ZFS SLOG/cache | `playbooks/zfs-slog-cache.yml` |

### Ansible Usage

```bash
cd ansible

# ZFS ARC tuning (included in main playbook)
ansible-playbook playbooks/proxmox.yml -i inventory/hosts.ini

# LVM to ZFS conversion (destructive!)
ansible-playbook playbooks/lvm-to-zfs.yml -e dangerous_confirm=yes

# ZFS pool creation (destructive!)
ansible-playbook playbooks/zfs-create.yml -e dangerous_confirm=yes

# ZFS SLOG/cache from MD RAID (destructive!)
ansible-playbook playbooks/zfs-slog-cache.yml
```

## Shell Scripts

| Script | Description |
|--------|-------------|
| `lvm-2-zfs.sh` | Converts LVM (MDADM) to ZFS with automatic RAID detection |
| `createzfs.sh` | Creates ZFS pool from specified devices |
| `slog-cache-2-zfs.sh` | Adds L2ARC cache and SLOG to existing ZFS pool |
| `benchmark_zfs.sh` | Benchmarks ZFS write performance |

## RAID Level Auto-Detection

| Drives | RAID Level | Equivalent |
|--------|------------|------------|
| 1 | zfs | Single |
| 2 | mirror | RAID1 |
| 3-5 | raidz-1 | RAID5 |
| 6-10 | raidz-2 | RAID6 |
| 11+ | raidz-3 | RAID7 |

## lvm-2-zfs.sh

Converts MDADM-based LVM to ZFS. Creates:

- `zfsbackup` (rpool/backup)
- `zfsvmdata` (rpool/vmdata)
- `/var/lib/vz/tmp_backup` (rpool/tmp_backup)

### Usage

```bash
# Requires explicit confirmation
LVM2ZFS_CONFIRM=yes ./lvm-2-zfs.sh [LVM_MOUNT_POINT]
```

## createzfs.sh

Creates ZFS pool from specified devices with automatic RAID level detection.

### Usage

```bash
# Production use (requires confirmation)
ZFS_CONFIRM=yes ./createzfs.sh poolname /dev/sda /dev/sdb

# Dry-run mode (shows planned actions)
ZFS_DRYRUN=yes ./createzfs.sh poolname /dev/sda /dev/sdb
```

Dry-run prints planned actions and exits non-zero without changes.

## slog-cache-2-zfs.sh

Converts MD RAID arrays mounted at `/ashimov/zfs-cache` and `/ashimov/zfs-slog`
to ZFS cache (L2ARC) and SLOG devices. Those are the paths the Hetzner
installimage script creates, so the two line up.

### Prerequisites

- MD RAID arrays mounted at `/ashimov/zfs-cache` and/or `/ashimov/zfs-slog`
- Existing ZFS pool to add devices to

### Usage

```bash
./slog-cache-2-zfs.sh [poolname]
```

Default pool name is `hddpool` if not specified. A missing mount point is
skipped, so a host with only a slog partition works fine.

The array is only torn down after the member list has been parsed out of
`/proc/mdstat` and every member checked to be a real block device. If the parse
looks wrong the script stops before unmounting anything.

## benchmark_zfs.sh

Runs ZFS write performance benchmarks (4K and 1M blocks).

### Usage

```bash
cd /path/to/zfs/dataset
./benchmark_zfs.sh
```

It writes roughly 20 GB of test files into the current directory and removes
them afterwards, so run it from the pool you want to measure. It refuses to run
outside a ZFS filesystem.

---

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
