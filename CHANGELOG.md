# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-02-22

### Fixed

#### Critical Fixes

- **Ansible: `pveceph install` hangs** — replaced `stdin: "Y\n"` with `DEBIAN_FRONTEND=noninteractive` environment variable, since `apt` reads from `/dev/tty`, not stdin (`proxmox_base/tasks/ceph.yml`)
- **Ansible: Invalid LXC config for Docker containers** — removed `lxc.kernel_modules: aufs ip_tables` (invalid in LXC 4.x, `aufs` removed from kernel 5.15+), added `lxc.cgroup2.devices.allow: a` for cgroup v2 compatibility on PVE 8/9 (`proxmox_lxc_docker/defaults/main.yml`, `helpers/pve-enable-lxc-docker.sh`)
- **ZFS: Unanchored mount-point grep corrupts `MY_LVM_DEV`** — `grep -F` replaced with `awk '$3 == mp'` to prevent multi-line results from bind-mounts (`zfs/lvm-2-zfs.sh`)
- **ZFS: fstab cleanup deletes unrelated entries** — `grep -Fv` replaced with anchored `awk` that only removes lines where mount-point field ($2) matches exactly, preserving comments and other entries (`zfs/lvm-2-zfs.sh`, `zfs/slog-cache-2-zfs.sh`)
- **CI: `community.general` collection not declared** — added `community.general >= 7.0.0` to `ansible/collections/requirements.yml` (required by `community.general.modprobe` in `proxmox_zfs_slog_cache` role)

#### High Priority Fixes

- **Tinc VPN: `tinc-down` disables IP forwarding globally** — removed `echo 0 > /proc/sys/net/ipv4/ip_forward` from `tinc-down.j2` which broke all VM/container networking when VPN interface went down
- **Tinc VPN: Duplicate `ip route add` always fails** — removed redundant route command from `tinc-up.j2` (connected route is auto-created by `ip addr add`)
- **Tinc VPN: Service enabled but never started** — added `state: started` to systemd task and `systemctl start` to shell script
- **Networking: `if-up.d` script with `set -e` halts network bringup** — removed `set -e`, added `|| echo "Warning: ..."` per-route error handling (`proxmox_networking/tasks/main.yml`)
- **ZFS: `parted print` aborts on disks with no partition table** — added `2>/dev/null` and `|| true` to handle fresh drives under `set -e` (`zfs/createzfs.sh`)
- **ZFS: Empty `readlink -f` result matches everything in grep** — added explicit empty-string check before `grep -qw` (`zfs/createzfs.sh`)
- **ZFS: PV device not validated as MD RAID** — added `^md[0-9]+$` regex validation and `grep -F` for fixed-string matching (`zfs/lvm-2-zfs.sh`)
- **Tinc shell script: Reset (`-r`) incorrectly requires `-c` flag** — wrapped `-c` requirement in `[ "$reset" != "yes" ]` guard (`networking/tincvpn.sh`)
- **Tinc shell script: Silent key generation failure** — added error check to `tincd -K4096` when public key exists but private key is missing (`networking/tincvpn.sh`)
- **Hetzner VNC: `MY_IFACE` not validated** — added empty-string check after `udevadm` detection to prevent incorrect network variable assignment (`hetzner/vnc-install-proxmox.sh`)
- **Debian 13: Kernel removal glob too broad** — replaced `'linux-image-6.*'` with `dpkg -l` + `mapfile` to precisely target only Debian-shipped kernels (`debian-2-proxmox/debian13-2-proxmox9.sh`)
- **Molecule: `test_sequence` missing `destroy` steps** — added `destroy` before converge and after verify to prevent stale state accumulation

#### Medium Priority Fixes

- **Removed dead `mdadm --remove` task** — command always fails after `mdadm --stop` since the device no longer exists (`proxmox_zfs_slog_cache/tasks/convert_md_to_zfs.yml`)
- **Subscription banner: Conflicting sed patterns** — aligned cron script and APT hook to use the same `sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}'` pattern (`proxmox_tuning/tasks/main.yml`, `install-post.sh`)
- **ZFS ARC MIN/MAX off-by-one** — separated MIN from MAX (was MAX-1 byte, preventing ARC from shrinking under memory pressure). Now uses 256MB/512MB for ≤16GB RAM, 512MB/1GB for ≤32GB RAM (`install-post.sh`)
- **ZFS comments incorrect** — fixed "11+ Drives = raidz-3" to "12+ Drives = raidz-3" to match code logic (`zfs/createzfs.sh`, `zfs/lvm-2-zfs.sh`)
- **ZFS benchmark: No filesystem check** — added verification that CWD is on ZFS before writing ~20GB of test data (`zfs/benchmark_zfs.sh`)
- **Tinc: `Compression` in wrong config file** — moved from per-host file (ignored by tincd) to `tinc.conf` where it takes effect (`networking/tincvpn.sh`)
- **Tinc: Wrong broadcast address** — changed `broadcast 0.0.0.0` to `10.10.1.255` for 10.10.1.0/24 subnet (`networking/tincvpn.sh`)
- **Hetzner VNC: NVMe controller extraction** — replaced `${dev::-2}` with `${dev%%n[0-9]*}` to handle NVMe namespaces ≥10 (`hetzner/vnc-install-proxmox.sh`)
- **Hetzner scripts: Missing root check** — added `id -u` validation to `hetzner/pve` and `hetzner/pbs`
- **Ansible: `proxmox_repo_key_path` undefined** — added default value in `proxmox_base/defaults/main.yml`

### Changed

- **Ansible-lint profile enforced** — removed `var-naming` from skip_list to enforce documented naming conventions
- **Debian 13 package compatibility** — replaced `mlocate` with `plocate`, removed `omping` and `software-properties-common` (unavailable on Debian 13) from `install-post.sh` and `proxmox_base` defaults

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
