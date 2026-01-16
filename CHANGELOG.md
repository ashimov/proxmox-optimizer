# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-01-16

### Added

#### Ansible Automation (Full Migration Complete)

- **Core Roles:**
  - `proxmox_base` - Repositories, packages, APT configuration
  - `proxmox_security` - Fail2ban, Lynis, rpcbind hardening
  - `proxmox_tuning` - Sysctl, journald, KSM, MOTD, limits
  - `proxmox_zfs` - ZFS ARC tuning, auto-snapshots
  - `proxmox_vfio` - IOMMU, VFIO for PCIe passthrough
  - `proxmox_networking` - vmbr0 routed bridge configuration
  - `provider_ovh` - OVH RTM installer, auto-detection
  - `provider_hetzner` - Hetzner network tuning, Storage Box

- **New Role: `proxmox_zfs_slog_cache`** - Convert MD RAID devices to ZFS SLOG/cache
  - Supports both cache (L2ARC) and SLOG (ZIL) devices
  - Automatic detection of MD RAID member devices
  - Uses disk-by-id paths for stability
  - Requires explicit confirmation (`zfs_slog_cache_confirm: true`)

- **New Role: `proxmox_tinc_vpn`** - Tinc VPN mesh network for Proxmox clusters
  - Automatic RSA key generation (4096-bit)
  - Systemd service management
  - Automatic public IP detection
  - Support for multi-node mesh topology
  - Host key distribution via playbook

- **New Role: `proxmox_lxc_docker`** - Docker support for LXC containers
  - Security warning and explicit confirmation required
  - Configures container privileges for Docker compatibility

- **New Role: `proxmox_nvidia`** - NVIDIA Docker runtime for GPU passthrough
  - NVIDIA Container Toolkit installation
  - Docker daemon configuration for NVIDIA runtime

- **Playbooks:**
  - `playbooks/proxmox.yml` - Main optimization playbook
  - `playbooks/zfs-slog-cache.yml` - ZFS SLOG/cache conversion
  - `playbooks/tinc-vpn.yml` - Multi-node Tinc VPN deployment
  - `playbooks/lxc-docker.yml` - LXC Docker configuration
  - `playbooks/nvidia-docker.yml` - NVIDIA Docker setup
  - `playbooks/network-configure.yml` - Network bridge setup
  - `playbooks/lvm-to-zfs.yml` - LVM to ZFS conversion
  - `playbooks/zfs-create.yml` - ZFS pool creation

- **Molecule Testing** - Syntax checks for all playbooks

#### Security Improvements

- **SHA256 Checksum Verification** - All remote script downloads now support checksum verification:
  - `XS_INSTALL_POST_SHA256` for install-post.sh
  - `XS_OVHRTM_SHA256` for OVH RTM installer
  - `MY_POSTINSTALL_SHA256` for Hetzner post-install
  - `PVE_EDGE_KERNEL_SHA256` for PVE Edge Kernel

- **Explicit Confirmation Requirements** for destructive operations:
  - `LVM2ZFS_CONFIRM=yes` for LVM to ZFS conversion
  - `LXC_DOCKER_CONFIRM=yes` for Docker in LXC (security-sensitive)
  - `ZFS_CONFIRM=yes` for ZFS pool creation

- **Input Validation:**
  - RFC 1123 hostname validation in installimage-proxmox.sh
  - Hostname length validation (max 253 characters per RFC 1035)
  - Container ID validation in pve-enable-lxc-docker.sh (numeric, range 100-999999999)
  - IP address validation for timezone detection and OVH ASN detection
  - Kernel version numeric validation
  - FQDN hostname validation in Debian conversion scripts

- **GPG Key Checksums** - Ansible roles now validate GPG key checksums when downloading

#### Shell Script Improvements

- Added `set -e` and `set -o pipefail` to all scripts for proper error handling
- Fixed unreachable code in installimage-proxmox.sh
- Fixed unquoted variables in slog-cache-2-zfs.sh
- Fixed run_cmd() return code in dry-run mode for createzfs.sh
- Added warning about outdated default URL in pve-edege-kernel.sh
- Added cleanup function to ERR trap in install-post.sh
- Use mktemp for secure temporary files in nvidia-docker.sh
- Added ZFS module load verification in createzfs.sh

### Changed

- **Ansible Migration Status: 100% Complete**
  - All shell scripts now have equivalent Ansible roles
  - Roles follow Ansible best practices (idempotency, handlers, molecule tests)

- Documentation reorganized with clear Ansible/Shell script sections

### Removed

- **Proxmox VE 7.x / Debian 11 (Bullseye) support** - End of life, no longer maintained
  - Removed `debian11-2-proxmox7.sh` conversion script
  - Removed all Debian 11 / Proxmox 7 references from documentation

### Fixed

- Fixed kernel version comparison logic in install-post.sh (kernel 7.0 was incorrectly handled)
- Fixed variable quoting in ZFS pool commands
- Fixed handler in proxmox_nvidia role (proper daemon reload)
- Fixed insecure file permissions (chmod 777 → 755) in installimage-proxmox.sh
- Fixed unquoted `$MY_IFACE` variable in vnc-install-proxmox.sh
- Fixed bug in tincvpn.sh that would delete `/etc/tinc/my_default_v4ip` (literal path) instead of cleanup
- Fixed missing else clause for ZFS pool creation with 0 devices in createzfs.sh
- Added sleep after modprobe zfs to prevent race condition in createzfs.sh
- Fixed placeholder GPG checksum for Trixie (now skips validation until PVE 9 release)

### Security

- Scripts no longer execute remote code without checksum verification by default
- Added security warnings for privileged operations (Docker in LXC)
- All destructive operations require explicit confirmation

## [1.0.0] - 2025-01-12

### Added

- Initial release with shell scripts for Proxmox VE optimization
- Post-installation optimizer (install-post.sh)
- Debian to Proxmox conversion scripts (11/12/13)
- Hetzner and OVH provider support
- ZFS management scripts (lvm-2-zfs.sh, createzfs.sh, slog-cache-2-zfs.sh)
- Network configuration scripts (network-configure.sh, tincvpn.sh)
- Helper scripts (pve-enable-lxc-docker.sh, pve-edege-kernel.sh)
- NVIDIA Docker support (nvidia-docker.sh)

### Supported Platforms

- Proxmox VE 9.x (Debian Trixie 13)
- Proxmox VE 8.x (Debian Bookworm 12)
- Proxmox VE 7.x (Debian Bullseye 11)
- Proxmox Backup Server 3.x
