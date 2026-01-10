# 💾 ZFS Management Scripts

## Overview

Collection of ZFS management scripts for Proxmox VE.

## Scripts

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
./lvm-2-zfs.sh [LVM_MOUNT_POINT]
```

## createzfs.sh

Creates ZFS pool from specified devices with automatic RAID level detection.

### Usage
```bash
./createzfs.sh poolname /dev/sda /dev/sdb
```

## slog-cache-2-zfs.sh

Adds ZFS cache (L2ARC) and SLOG to existing pool.

### Usage
```bash
./slog-cache-2-zfs.sh poolname
```

## benchmark_zfs.sh

Runs ZFS write performance benchmarks (4K and 1M blocks).

### Usage
```bash
./benchmark_zfs.sh
```

---
*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*
