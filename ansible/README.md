# Ansible Migration

This directory contains the Ansible-based replacement for the current shell scripts.
Core roles are fully implemented, and remaining features are tracked in `ROADMAP.md` at the repo root.

## Quick Start

Requires the full `ansible` package (ansible-core is not supported).

1) Edit `ansible/inventory/hosts.ini` with your Proxmox hosts
2) Adjust variables in `ansible/inventory/group_vars/all.yml`
3) Install required collections:

```bash
cd ansible
ansible-galaxy collection install -r collections/requirements.yml
```

Required collections: `ansible.utils`, `ansible.posix`.

4) Run:

```bash
cd ansible
ansible-playbook playbooks/proxmox.yml
```

## Roles

| Role | Description | Status |
|------|-------------|--------|
| `proxmox_base` | Repos, base packages, core APT config | ✅ 100% |
| `proxmox_security` | Fail2ban, Lynis, rpcbind | ✅ 100% |
| `proxmox_tuning` | Sysctl, journald, logrotate, KSM, MOTD, bashrc | ✅ 100% |
| `proxmox_zfs` | ZFS ARC tuning and optional auto-snapshot | ✅ 100% |
| `proxmox_vfio` | IOMMU and VFIO modules/blacklists | ✅ 100% |
| `proxmox_networking` | vmbr0 routed bridge (opt-in) | ✅ 100% |
| `proxmox_lxc_docker` | Docker support for LXC containers (opt-in, security warning) | ✅ 100% |
| `proxmox_nvidia` | NVIDIA Docker runtime for GPU passthrough | ✅ 100% |
| `proxmox_zfs_slog_cache` | Convert MD RAID to ZFS SLOG/cache (destructive) | ✅ 100% |
| `proxmox_tinc_vpn` | Tinc VPN mesh network for Proxmox clusters | ✅ 100% |
| `provider_ovh` | OVH RTM installer with auto-detection | ✅ 100% |
| `provider_hetzner` | Hetzner network tuning and Storage Box | ✅ 100% |

## Safety

- Networking changes are **opt-in**. Set `proxmox_configure_networking: "yes"` and
  define the required variables.
- Provider roles are **opt-in** via `proxmox_provider`.
- Provider auto-detection by ASN is enabled by default.
- Destructive workflows are available via guarded playbooks in `ansible/playbooks`
  and require `-e dangerous_confirm=yes`. Installimage workflows remain out of scope.
- LXC Docker role is **opt-in** and requires explicit confirmation (`lxc_docker_confirm: true`).
- NVIDIA role is standalone and not included in the main playbook.
- ZFS SLOG/cache role is **destructive** and requires explicit confirmation (`zfs_slog_cache_confirm: true`).
- Tinc VPN role is standalone for multi-node mesh setup.

## Testing

### Smoke Test

Run the smoke test playbook to verify your configuration:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/smoke-test.yml --check
```

### Test Inventory

Use the test inventory for CI/CD and local testing:

```bash
cd ansible
ansible-playbook -i inventory/test.ini playbooks/smoke-test.yml --check
```

### Syntax Check

Verify playbook syntax without running:

```bash
cd ansible
ansible-playbook playbooks/proxmox.yml --syntax-check
```

### Dry Run

Preview changes without applying:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/proxmox.yml --check --diff
```

### Validation

Validate AMD fixes, guest agent installation, and Open vSwitch/ifupdown2 package state:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/validate-postinstall.yml
```

### Molecule

Molecule scaffolding is available for local checks:

```bash
cd ansible
molecule test
```

The default scenario is a noop smoke test and should be extended for real Proxmox hosts.

## Variables

All variables are documented in `inventory/group_vars/all.yml`. Key variables:

### Base Configuration
- `xs_aptupgrade`: Update packages (default: "yes")
- `xs_utils`: Install utility packages (default: "yes")
- `xs_kernelheaders`: Install kernel headers (default: "yes")
- `xs_manage_sources_list`: Manage `/etc/apt/sources.list` (default: "yes")

### Security
- `xs_fail2ban`: Enable fail2ban (default: "yes")
- `xs_lynis`: Install Lynis security scanner (default: "yes")
- `xs_disablerpc`: Disable rpcbind (default: "yes")

### Tuning
- `xs_ksmtuned`: Enable KSM tuning (default: "yes")
- `xs_nosubbanner`: Remove subscription banner (default: "yes")
- `xs_pigz`: Install pigz parallel compression (default: "yes")
- `xs_bashrc`: Customize bashrc (default: "yes")
- `xs_motd`: Customize MOTD (default: "yes")

### ZFS
- `xs_zfsarc`: Configure ZFS ARC (default: "yes")
- `xs_zfsautosnapshot`: Enable auto-snapshots (default: "no")

### VFIO
- `xs_vfio_iommu`: Enable IOMMU/VFIO (default: "yes")

### LXC Docker (Security-Sensitive)

- `lxc_docker_container_id`: Container ID to configure (required)
- `lxc_docker_confirm`: Must be `true` to proceed (default: false)
- `lxc_docker_restart_container`: Restart container after config (default: true)

### NVIDIA Docker

- `nvidia_docker_enabled`: Enable NVIDIA Docker installation (default: true)
- `nvidia_docker_reboot`: Reboot after installation (default: false)

### Networking
- `proxmox_configure_networking`: Enable networking configuration (default: "no")
- `proxmox_extra_routes`: Optional list of routed IP ranges

### ZFS SLOG/Cache (Destructive)

- `zfs_pool_name`: ZFS pool to add SLOG/cache to (default: "hddpool")
- `zfs_cache_mount_point`: MD RAID mount for cache (default: "/xshok/zfs-cache")
- `zfs_slog_mount_point`: MD RAID mount for SLOG (default: "/xshok/zfs-slog")
- `zfs_slog_cache_confirm`: Must be `true` to proceed (default: false)

### Tinc VPN

- `tinc_network_name`: VPN network name (default: "xsvpn")
- `tinc_vpn_ip_last`: Last octet of VPN IP for this host (required per-host)
- `tinc_connect_to`: Hostname to connect to in mesh (required per-host)
- `tinc_port`: Tinc port (default: 655)
- `tinc_public_ip`: Public IP (auto-detected if not set)

### Providers
- `proxmox_provider`: Set to "ovh" or "hetzner" to enable provider-specific tasks
- `xs_ovhrtm`: Install OVH RTM (default: "yes")
- `xs_hetzner_storagebox`: Enable Storage Box auto-mount (default: false)
- `xs_hetzner_robot`: Enable Hetzner Robot API integration (default: false)

Store provider credentials in host_vars when possible.
- `xs_hetzner_network_tuning`: Apply Hetzner network tuning (default: true)

## CI/CD

The project includes GitHub Actions workflows for:
- **Shellcheck**: Linting shell scripts
- **Ansible-lint**: Linting Ansible playbooks and roles
- **YAML lint**: Validating YAML syntax
- **Molecule**: Basic Ansible test scaffold

Workflows are blocking.
