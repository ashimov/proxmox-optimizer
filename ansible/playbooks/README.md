# Dangerous Ops Playbooks

These playbooks perform destructive operations. They are guarded and will not
apply changes unless you pass `-e dangerous_confirm=yes`.

Backups are written to `/root/ansible-backups` by default. Override with
`-e dangerous_backup_dir=/path`.

## zfs-create.yml

Create a new ZFS pool using `zfs/createzfs.sh`.

Example:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/zfs-create.yml \
  -e dangerous_confirm=yes \
  -e zfs_pool_name=hdd \
  -e 'zfs_devices=["/dev/sda","/dev/sdb"]'
```
The playbook sets `ZFS_CONFIRM=yes` when invoking the script.

Rollback:
- This is destructive. If a pool is created incorrectly, you must manually
  destroy the pool and restore data from backups.
- Review the preflight report in `/root/ansible-backups/zfs-create-*.log`.

## lvm-to-zfs.yml

Convert LVM (MDADM) to ZFS using `zfs/lvm-2-zfs.sh`.

Example:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/lvm-to-zfs.yml \
  -e dangerous_confirm=yes \
  -e lvm_mount_point=/var/lib/vz
```

Rollback:
- There is no automated rollback. Restoring requires backups or reinstall.
- Review the preflight report in `/root/ansible-backups/lvm-to-zfs-*.log`.

## network-configure.yml

Configure vmbr0 routed networking using `networking/network-configure.sh`.

Example:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/network-configure.yml \
  -e dangerous_confirm=yes \
  -e network_dhcp_public=no
```

Rollback:
- Restore `/etc/network/interfaces` and DHCP configs from the backup files in
  `/root/ansible-backups`, then reboot or restart networking.
- Review the preflight report in `/root/ansible-backups/network-configure-*.log`.

## Validation (Safe)

Use `playbooks/validate-postinstall.yml` to verify AMD fixes, guest agent
installation, and Open vSwitch/ifupdown2 package state.
