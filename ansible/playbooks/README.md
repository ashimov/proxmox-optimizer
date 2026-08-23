# Playbooks

`proxmox.yml` is the normal entry point. Everything else here is either a
validation run or a destructive operation with its own confirmation flag.

All playbooks target the `[proxmox]` group. Copy `inventory/hosts.ini.example`
to `inventory/hosts.ini` (the working inventory is git-ignored).

## Safe

| Playbook | What it does |
|----------|--------------|
| `proxmox.yml` | Base config, security, tuning, ZFS ARC, VFIO, optional provider role |
| `validate-postinstall.yml` | Checks AMD fixes, guest agent, ifupdown2/openvswitch state |
| `smoke-test.yml` | Reports version, codename, CPU, RAM, ZFS availability |

```bash
ansible-playbook playbooks/proxmox.yml
ansible-playbook playbooks/proxmox.yml --tags security,tuning
ansible-playbook playbooks/validate-postinstall.yml
```

## Destructive

These will not change anything unless you pass the confirmation variable.
Preflight reports (lsblk, pvs/vgs/lvs, fstab, routes) are written to
`/root/ansible-backups` first; override with `-e dangerous_backup_dir=/path`.

Run `--check --diff` once before applying, and keep an out-of-band console open.

### zfs-create.yml

Creates a pool with `zfs/createzfs.sh`. The playbook passes `ZFS_CONFIRM=yes`
to the script.

```bash
ansible-playbook playbooks/zfs-create.yml \
  -e dangerous_confirm=yes \
  -e zfs_pool_name=hdd \
  -e 'zfs_devices=["/dev/sda","/dev/sdb"]'
```

Rollback: none. Destroy the pool by hand and restore from backup.
Preflight: `/root/ansible-backups/zfs-create-*.log`.

### lvm-to-zfs.yml

Converts an LVM-on-MD volume with `zfs/lvm-2-zfs.sh`. The playbook passes
`LVM2ZFS_CONFIRM=yes` to the script.

```bash
ansible-playbook playbooks/lvm-to-zfs.yml \
  -e dangerous_confirm=yes \
  -e lvm_mount_point=/var/lib/vz
```

Rollback: none. Restore from backup or reinstall.
Preflight: `/root/ansible-backups/lvm-to-zfs-*.log`.

### zfs-slog-cache.yml

Turns the MD arrays mounted at `/ashimov/zfs-cache` and `/ashimov/zfs-slog`
into ZFS cache and SLOG devices. Prompts for the word `DESTROY`.

```bash
ansible-playbook playbooks/zfs-slog-cache.yml -e zfs_pool_name=hddpool
```

The role refuses to touch anything unless the mount source is an `mdN` device
and every parsed member is a real block device.

### network-configure.yml

Rewrites `/etc/network/interfaces` as a routed vmbr0 with
`networking/network-configure.sh`. This can lock you out of SSH.

```bash
ansible-playbook playbooks/network-configure.yml -e dangerous_confirm=yes
```

Rollback: the previous `/etc/network/interfaces` is in
`/root/ansible-backups/interfaces-*`. Restore it and restart networking.
Preflight: `/root/ansible-backups/network-configure-*.log`.

### lxc-docker.yml

Drops AppArmor confinement and capability limits in one container so Docker
can run in it. Use a VM instead where you can.

```bash
ansible-playbook playbooks/lxc-docker.yml \
  -e lxc_docker_container_id=100 \
  -e lxc_docker_confirm=true
```

## Other

| Playbook | Notes |
|----------|-------|
| `tinc-vpn.yml` | Mesh VPN across nodes, runs `serial: 1` and distributes host keys through `ansible/tinc_hosts/` |
| `nvidia-docker.yml` | Installs `nvidia-container-toolkit` and wires it into Docker |
