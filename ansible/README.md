# Ansible

Roles and playbooks for setting up and maintaining Proxmox hosts. This is where
new work goes: the shell scripts stay for the cases where Ansible cannot run
yet, such as a rescue system or a Debian box that is not Proxmox yet.

## Quick Start

Needs the full `ansible` package, not just ansible-core, plus `netaddr` on the
control node. Without netaddr the `ipaddr` filter fails and the networking,
firewall and provider roles stop.

```bash
pip install -r ansible/requirements.txt
cd ansible
ansible-galaxy collection install -r collections/requirements.yml

cp inventory/hosts.ini.example inventory/hosts.ini   # hosts.ini is git-ignored
$EDITOR inventory/hosts.ini
$EDITOR inventory/group_vars/all.yml

ansible-playbook playbooks/proxmox.yml --check --diff   # look first
ansible-playbook playbooks/proxmox.yml
```

Collections: `ansible.utils`, `ansible.posix`, `community.general`.

## Roles

| Role | Description | Status |
|------|-------------|--------|
| `proxmox_base` | Repos, base packages, core APT config | in `proxmox.yml` |
| `proxmox_security` | Fail2ban and Lynis, rpcbind off | in `proxmox.yml` |
| `proxmox_tuning` | Sysctl, journald, logrotate, KSM, MOTD, bashrc | in `proxmox.yml` |
| `proxmox_zfs` | ZFS ARC tuning and optional auto-snapshot | in `proxmox.yml` |
| `proxmox_vfio` | IOMMU and VFIO modules/blacklists | in `proxmox.yml` |
| `proxmox_ssh` | sshd policy, keys over passwords | opt-in |
| `proxmox_updates` | unattended-upgrades for security updates | opt-in |
| `proxmox_firewall` | pve-firewall ruleset for the management ports | opt-in |
| `proxmox_notifications` | Mail alerts: ZED, smartd, root alias, PVE user | opt-in |
| `proxmox_backup` | PBS storage and a vzdump job, checks one exists | opt-in |
| `proxmox_networking` | vmbr0 routed bridge | opt-in |
| `proxmox_lxc_docker` | Docker inside LXC (drops isolation) | opt-in |
| `proxmox_nvidia` | NVIDIA Container Toolkit | standalone playbook |
| `proxmox_zfs_slog_cache` | Convert MD RAID to ZFS SLOG/cache (destructive) | standalone playbook |
| `proxmox_tinc_vpn` | Tinc VPN mesh between nodes | standalone playbook |
| `provider_ovh` | OVH RTM installer with auto-detection | via `proxmox_provider` |
| `provider_hetzner` | Hetzner network tuning and Storage Box | via `proxmox_provider` |

## Safety

The five roles marked opt-in above do nothing until you set their `*_manage`
variable to `"yes"`. Two of them can lock you out of a remote host, so read the
defaults before switching them on:

- `proxmox_ssh` refuses to disable password logins when root has no
  `authorized_keys`, and validates the config with `sshd -t` before restarting.
- `proxmox_firewall` refuses to enable the firewall when the address you are
  connected from is outside `proxmox_firewall_management_networks`.

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

### Safety and hardening knobs

- `xs_coredump`: Write kernel core dumps to `/var/crash` (default: `"no"`). A dump
  of a Proxmox daemon contains cluster keys and auth tickets in cleartext.
- `xs_hugepages`: Number of hugepages to preallocate (default: empty = none).
- `xs_lynis_key_sha256`, `proxmox_key_checksums`: Pin the APT signing keys.
- `zfs_slog_cache_confirm`, `lxc_docker_confirm`, `dangerous_confirm`: Required
  before any destructive playbook does anything.

### LXC Docker (Security-Sensitive)

- `lxc_docker_container_id`: Container ID to configure (required)
- `lxc_docker_confirm`: Must be `true` to proceed (default: false)
- `lxc_docker_restart_container`: Restart container after config (default: true)

### NVIDIA Container Toolkit

Installs `nvidia-container-toolkit` from the `libnvidia-container` repository.
The old `nvidia-docker2` package and its repository are end-of-life and publish
nothing for Debian 12/13.

- `nvidia_docker_enabled`: Enable installation (default: true)
- `nvidia_docker_reboot`: Reboot after installation (default: false)
- `nvidia_configure_docker_runtime`: Run `nvidia-ctk runtime configure` (default: true)
- `nvidia_toolkit_gpg_sha256` / `nvidia_toolkit_list_sha256`: Pinned SHA256 of the
  signing key and repository list (empty = TLS only, warns at runtime)

### Networking
- `proxmox_configure_networking`: Enable networking configuration (default: "no")
- `proxmox_extra_routes`: Optional list of routed IP ranges

### ZFS SLOG/Cache (Destructive)

- `zfs_pool_name`: ZFS pool to add SLOG/cache to (default: "hddpool")
- `zfs_cache_mount_point`: MD RAID mount for cache (default: "/ashimov/zfs-cache")
- `zfs_slog_mount_point`: MD RAID mount for SLOG (default: "/ashimov/zfs-slog")
- `zfs_slog_cache_confirm`: Must be `true` to proceed (default: false)

### Tinc VPN

- `tinc_network_name`: VPN network name (default: "pvemesh")
- `tinc_vpn_ip_last`: Last octet of VPN IP for this host (required per-host)
- `tinc_connect_to`: Hostname to connect to in mesh (required per-host)
- `tinc_port`: Tinc port (default: 655)
- `tinc_public_ip`: Public IP (auto-detected if not set)
- `tinc_cipher` / `tinc_digest`: Tunnel crypto (defaults: `aes-256-cbc` / `sha256`).
  The tinc 1.0 legacy protocol otherwise falls back to blowfish/SHA1. **Every node
  in the mesh must use the same values.** Changing them breaks an existing mesh
  until every node is updated.
- `tinc_compression`: Compression level (default: `0`, off). Compressing before
  encryption leaks information about the plaintext.
- `tinc_hosts`: Other nodes in the mesh. Every field is validated before it is
  templated into a host config file.

> **Breaking change in 1.0.4:** the default network name changed, so the config
> directory is now `/etc/tinc/pvemesh` and the unit is `tinc-pvemesh.service`.
> Set `tinc_network_name` to the previous value to keep an existing mesh running.

### Providers
- `proxmox_provider`: Set to "ovh" or "hetzner" to enable provider-specific tasks
- `xs_ovhrtm`: Install OVH RTM (default: "yes")
- `xs_hetzner_storagebox`: Enable Storage Box auto-mount (default: false)
- `xs_hetzner_robot`: Enable Hetzner Robot API integration (default: false)

Store provider credentials in host_vars when possible.
- `xs_hetzner_network_tuning`: Apply Hetzner network tuning (default: true)

## CI/CD

The project includes GitHub Actions workflows for:
- **Shellcheck**: Lints every `*.sh` plus the extensionless `hetzner/pve` and
  `hetzner/pbs`, at `severity=style` (the tree is clean at that level)
- **Ansible-lint**: Linting Ansible playbooks and roles
- **YAML lint**: Validating YAML syntax
- **Molecule**: Syntax checks, plus a `--list-hosts` gate that fails when a
  playbook targets a group that does not exist in the inventory, and a guard
  against reintroducing legacy project identifiers

### Inventory

`inventory/hosts.ini` is git-ignored: copy `inventory/hosts.ini.example` and fill
in real addresses. Every playbook targets the `[proxmox]` group.

Workflows are blocking.
