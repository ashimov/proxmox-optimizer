# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2026-08-23

Went through the whole tree again, this time reading the shell scripts and the
roles side by side. Most of what came out of it is below. Read the breaking
section before upgrading an existing host.

### Added

- Release pipeline. Tagging `v*` builds `SHA256SUMS` over every script, signs it
  with cosign keyless and opens a draft release. `scripts/make-checksums.sh`
  builds the same list locally. The README instructions finally point at
  something that exists.
- Five roles for the things this repo never touched, all shipped switched off:
  - `proxmox_ssh`. A fresh Proxmox lets root in over SSH with a password. This
    sets keys-only, tightens the usual knobs, and refuses to disable password
    logins when root has no authorized_keys. `sshd -t` runs before any restart.
  - `proxmox_updates`. unattended-upgrades for Debian security updates only.
    Proxmox repo updates stay manual, and the cluster packages are blacklisted.
  - `proxmox_firewall`. pve-firewall with the management ports limited to the
    networks you list. It refuses to enable the firewall if the address you are
    connected from is not one of them.
  - `proxmox_notifications`. ZED on a degraded pool, smartd on a failing disk,
    root's mail pointed at a real address, `root@pam` given that address, and an
    optional smarthost.
  - `proxmox_backup`. Attaches a Proxmox Backup Server, creates a vzdump job,
    and by default fails on a host that has no backup job at all.
- Test fixture in `tests/fixture`. The roles abort on anything that is not
  Proxmox, so until now CI never evaluated a single task. The fixture fakes
  `/etc/pve` and the `pve*` binaries, and a new workflow runs the whole of
  `proxmox.yml` in check mode plus a set of rendering assertions. It found four
  bugs on the first run, listed below.
- `ansible/requirements.txt` for the control node.
- `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue and pull request templates, and a
  dependabot config. The actions are pinned by SHA, which means nothing updates
  them unless something says so.
- Tags for 1.0.0, 1.0.2 and 1.0.3, which shipped without any. That is why the
  tag list used to jump from v1.0.1 to v1.0.4. The release workflow skips tags
  from before it existed instead of failing on them.

### Breaking

- Tinc network renamed to `pvemesh`. Config is now in `/etc/tinc/pvemesh` and
  the unit is `tinc-pvemesh.service`. To keep an existing mesh, set
  `tinc_network_name` back to the old value, or move the directory and re-run.
- Tinc now pins `Cipher = aes-256-cbc`, `Digest = sha256` and turns compression
  off. All nodes have to agree on those, so update the whole mesh at once.
- SLOG/cache mount points are `/ashimov/zfs-cache` and `/ashimov/zfs-slog`.
  While renaming these I noticed the installimage script was creating the cache
  partition as `zfs-L2ARC` while the converter looked for `zfs-cache`, so the
  cache device was never actually picked up. Both use the same path now.
- The Debian to Proxmox converters no longer create `admin@pve`. Set
  `XS_CREATE_ADMIN_USER=yes` if you want it, plus `XS_ADMIN_PASSWORD` for
  unattended runs.
- Both Hetzner installers now refuse to start without `INSTALL_CONFIRM=yes`.
- NVIDIA: `nvidia-docker2` is gone, replaced by `nvidia-container-toolkit`.
  The role variables `nvidia_docker_gpg_sha256` / `nvidia_docker_list_sha256`
  are now `nvidia_toolkit_gpg_sha256` / `nvidia_toolkit_list_sha256`.
- Core dumps are off by default. `XS_COREDUMP=yes` (or `xs_coredump: "yes"`)
  brings the old behaviour back.
- `ansible/inventory/hosts.ini` is git-ignored. Copy `hosts.ini.example`.

### Security

- The install instructions in the README were the worst thing in the repo: a
  one-liner that pulled a script off the mutable `master` branch and piped it
  straight into bash, with `wget -c` on top, which appends to a leftover partial
  file and then executes the result. Quick Start is now download, verify against
  the release `SHA256SUMS`, then run. Every documented URL points at a tag and
  `-c` is gone everywhere.
- The VNC installer bound QEMU's VNC server to `0.0.0.0:5900` from a rescue
  system with a public IP and no firewall. VNC auth only uses the first 8
  characters of the password, so the "32 character random password" was worth 8.
  It binds to `127.0.0.1` now (`MY_VNC_BIND`) and the docs show the SSH tunnel.
- `apt purge 'linux-image-6.*'` in `debian12-2-proxmox8.sh`, `hetzner/pve` and
  `hetzner/pbs`: apt reads that as a regex. On the wrong host it takes the only
  bootable kernel with it. All three now list Debian kernels explicitly and skip
  the running one and anything `-pve`.
- fail2ban could sit there doing nothing. The jail hard-coded
  `logpath = /var/log/daemon.log`, which does not exist without rsyslog, and a
  missing logpath makes the jail fail to start while the install still says it
  succeeded. Falls back to the journald backend now, matches `pveproxy` as well
  as `pvedaemon`, and checks `fail2ban-client status proxmox` at the end.
- Tinc was running on the tinc 1.0 defaults, which means blowfish and SHA1, with
  LZO compression on top of the encrypted tunnel. Pinned, see breaking.
- The v1.0.3 input validation missed a few spots: `tinc_connect_to` and the
  `tinc_hosts` entries were templated into config files unchecked, the shell
  script did not validate `-p`, `-a` or `-c`, and `lxc_docker_container_id` went
  into a path with no check at all. All validated now.
- `WIPE_PARTITION_TABLE=TRUE` was the default in both Hetzner installers with
  nothing but a `sleep` in front of `parted mklabel gpt`. Now they need
  `INSTALL_CONFIRM=yes` and print the target disks with model and serial first.
- `admin@pve` was created with Administrator on `/` and the password prompt ran
  last, after `install-post.sh`. Anything failing in between left an admin
  account with no password. Opt-in now, password set immediately, and a
  non-interactive run without `XS_ADMIN_PASSWORD` deletes the half-made account.
- `kernel.core_pattern` was set unconditionally. A dump of pvedaemon has cluster
  keys and auth tickets in it, in cleartext, on disk, with no rotation. Off by
  default; when enabled, `/var/crash` is `0700`, `fs.suid_dumpable=0` and dumps
  are rotated.
- `log_martians` was set to `0`, which throws away the evidence of spoofed
  traffic. Back to `1`.
- Added `XS_PROXMOX_KEY_SHA256` and `XS_CISOFY_KEY_SHA256` to the shell path
  (the Ansible roles already had this) and a warning when the Proxmox key
  checksum for the running codename is not pinned.
- `install-post.env` is only sourced if the directory holding it is root-owned
  and not writable by anyone else, and never if it is a symlink.

### Fixed

Found by the new fixture on its first runs:

- Roles took their `xs_*` toggles from `group_vars/all.yml` only, so pointing
  ansible at any other inventory failed with "xs_noaptlang is undefined" on the
  sixth task. `proxmox_base` and `provider_hetzner` now carry their own defaults.
- `meta: end_role` needs ansible-core 2.18. The project supports 2.16, so
  `proxmox_nvidia` would have failed for anyone on the declared version range.
  Role guards moved to `when:` on the role entry.
- `netaddr` was never declared anywhere, and `ansible.utils.ipaddr` needs it.
  The networking, firewall and provider roles stop without it.
- `stdout_callback = yaml` resolves to `community.general.yaml`, which was
  removed in community.general 12. Switched to the builtin default plus
  `callback_result_format`, which does not depend on a collection version.
- `regex_search(...) | default(['8'])` does not fall back the way it looks like
  it does: `regex_search` returns None when it does not match, and `default()`
  only fires on undefined. Unexpected `pveversion` output gave
  "NoneType is not iterable" instead of the intended 8. Same shape in
  `proxmox_base/ceph.yml`, `proxmox_tuning` and the Hetzner Robot credential
  parsing, all four now use `default(x, true)`. The AMD branch is the one that
  parses `pveversion`, so the fixture runs the playbook a second time with that
  branch forced.

And the CI that was supposed to catch all this:

- Every workflow using `setup-python` with `cache: pip` failed at the Python
  step, because the cache needs a `requirements.txt` or `pyproject.toml` to hash
  and the repo had neither. yamllint, ansible-lint and molecule had been red on
  every run for that reason alone.
- ansible-lint: 1.0.2 removed `var-naming` from the skip list "to enforce
  documented naming conventions", but `var-naming[no-role-prefix]` wants every
  variable renamed to `<role_name>_*`, which is the whole documented `xs_*`
  interface. 202 findings, red ever since. That one sub-rule is skipped now, the
  rest of `var-naming` still applies.
- molecule: the `delegated` driver no longer exists, and molecule repoints
  `ANSIBLE_ROLES_PATH` at its own ephemeral directory, so the syntax checks
  failed for every playbook that uses a role while the task-only ones passed.

And the rest:

- Two `replace` tasks in `proxmox_base` used `\\s` and `\\[` inside single-quoted
  YAML, so the regex reaching Python had literal backslashes in it and matched
  nothing. Both "normalize signed-by" tasks were no-ops that reported ok.
- `tinc-vpn.yml` and `zfs-slog-cache.yml` addressed `proxmox_nodes`, a group that
  does not exist in the inventory. Zero hosts, exit code 0, no complaints.
- `lvm-to-zfs.yml` called a script that requires `LVM2ZFS_CONFIRM=yes` without
  passing it, so the documented path always failed on the last step.
- The NVIDIA role built `.../debian12.11/nvidia-docker.list` from
  `ansible_distribution_version`. No such path exists. Moot now that the role
  uses the distribution-independent repo, but it was a guaranteed 404.
- ZFS ARC min was one byte below max in the Ansible role (536870911/536870912),
  which pins the ARC and stops it shrinking under memory pressure. Now 256M/512M
  and 512M/1G, same as the shell script, with an assertion that min < max.
- Both ZFS converters parsed `/proc/mdstat` with a fixed column offset. A line
  like `md5 : active (auto-read-only) raid1 sda4[0]` shifts the fields, so the
  device list came out as `/dev/raid1`, and by then the array was already gone.
  They match `name[index]` tokens now and every member is checked to be a block
  device before anything is unmounted, stopped or zeroed.
- In the same role, `... | select() | list | default(md_members)` never fell back:
  `default()` only fires on undefined, not on an empty list, so `zpool add` could
  be called with no devices at all after the array was destroyed.
- pigz replacement in the Ansible role used `mv /bin/gzip /bin/gzip.original`.
  A gzip package upgrade undoes that, and a second run after someone deleted
  `gzip.original` would "back up" the wrapper as the original. Uses
  `dpkg-divert` now, like the shell script always did.
- Tinc broadcast address in the Ansible template was still `0.0.0.0`.
- Removed the dead `mdadm --remove` from `zfs/lvm-2-zfs.sh`; it always fails
  because `--stop` already took the device away.
- `sh -c "echo -e ..."` wrote a literal `-e` into `/etc/default/locale`, since
  `/bin/sh` on Debian is dash.
- `network-configure.yml` passed `XS_DHCP_PUBLIC` to a script that never read it.
  Dropped the variable.
- Hetzner Robot RDNS posted JSON to `/rdns`. The webservice wants a form-encoded
  `POST /rdns/<ip>` with `ptr`.
- `mount | grep -F "$MOUNT_POINT"` in `slog-cache-2-zfs.sh` also matched
  `/ashimov/zfs-cache2`. Same bug as the one fixed in `lvm-2-zfs.sh` in 1.0.2.
- `poolprefix=${poolname/pool/}` stripped "pool" anywhere in the name, so
  `mypoolstorage` became `mystoragepool`.
- Four scripts died instead of falling through to their fallback: with `set -e`,
  a `grep -v vmbr` that matches nothing, or `ip route get 8.8.8.8` on a host with
  no egress, ends the script. Affected both Debian converters, `tincvpn.sh` and
  `network-configure.sh`.
- Unset variables in the Hetzner installers (`$1`, `$2`, `$3`, `MY_OS`,
  `MY_USE_LVM`), and `OS` was never assigned at all when `MY_OS` was set.
- `XS_CEPH_FAIL_HARD` had no default, so under `set -u` the Ceph error handler
  aborted with "unbound variable" instead of doing its job.
- The converters now look for `install-post.sh` next to the script rather than
  in the current directory.
- Dropped the `aufs`/`ip_tables` line from the LXC Docker warnings; those were
  removed from the config back in 1.0.2.
- `vm.min_free_kbytes` was a flat 1 GB regardless of host size, and 72 hugepages
  were preallocated unconditionally. The reserve scales with RAM now (64M to 1G)
  and hugepages are opt-in through `XS_HUGEPAGES` / `xs_hugepages`.

### CI

- shellcheck runs at `severity=style` instead of `warning` (the leftover item
  from 1.0.3). The tree is clean at that level, and it now also covers
  `hetzner/pve` and `hetzner/pbs`, which have no `.sh` extension and were being
  skipped.
- New `fixture` workflow: builds a fake Proxmox host in a Debian container and
  runs `proxmox.yml` in check mode end to end, plus assertions on the templates
  and the mdstat parsing.
- New `release` workflow, described above.
- Molecule verify got a `--list-hosts` gate that fails when a playbook matches
  no hosts, a regression test for the `signed-by` regexes, and a check that the
  old project identifiers do not come back.

### Changed

- All documented download URLs point at a release tag instead of `master`.
- Dates on the 1.0.0 and 1.0.1 entries were a year early, corrected against the
  commits they shipped from.
- `inventory/hosts.ini.example` defines a usable `[proxmox]` group.
- Documentation updated across the board: README, ansible/README, and the
  per-directory ones for hetzner, zfs, networking, nvidia, helpers and
  debian-2-proxmox.

## [1.0.3] - 2026-05-18

Injection and supply-chain pass.

### Security

- `hetzner/installimage-proxmox.sh` built its installimage call as a string and
  ran it through `bash -c`. Hostname, install target and partition sizes are
  validated now, and the command is built as an argv array passed to
  `screen -mS ... --`, so no shell metacharacter gets a say.
- The same script downloaded its post-install file without `--fail`, so a 404
  page could end up executed. Uses `wget --fail --timeout=30 --tries=3` and
  removes the partial file on error.
- Added `assert` validation for the `tinc_*` and `proxmox_*` variables that get
  templated into config files and shell scripts, and `| quote` in tinc-up and
  tinc-down.
- The VNC installer booted whatever ISO it downloaded. It now wants
  `MY_PVE_ISO_SHA256` / `MY_PBS_ISO_SHA256`, or an explicit
  `MY_ISO_ALLOW_UNVERIFIED=yes`, and dropped the `-c` resume flag.
- The Debian converters checked the `install-post.sh` checksum after `chmod +x`.
  Reordered so the checksum is enforced and verified before anything runs.
- `proxmox_security` accepts `xs_lynis_key_sha256` and passes it to `get_url`,
  with a runtime warning when it is unset.
- `proxmox_nvidia` gained checksum variables for the GPG key and repo list, plus
  `validate_certs: true`.
- `proxmox_extra_routes` ran `ip route replace` through `command:` with an
  interpolated interface name. Converted to `argv:` and the assert now requires
  the interface name to match `^[a-zA-Z0-9_-]{1,15}$`.

### Fixed

- `pveceph install` failures were swallowed. The exit code is captured, a
  recovery hint is printed, and `XS_CEPH_FAIL_HARD=yes` makes it fatal.
- `mktemp /tmp/...` in `zfs/lvm-2-zfs.sh` ignored `$TMPDIR`; switched to
  `mktemp -t`.
- `networking/tincvpn.sh` wrote a unit file that depended on `tincd` still being
  where `command -v` found it. Resolves the path once and embeds it.
- `nvidia/nvidia-docker.sh` used `#!/bin/bash`; normalised to
  `#!/usr/bin/env bash` like the rest.

### Changed

- Galaxy collections have upper bounds now (`ansible.utils <3.0.0`,
  `ansible.posix <2.0.0`, `community.general <11.0.0`) so a major version bump
  cannot break the playbooks mid-release.
- README got a proper warning block for the destructive playbooks, with the
  correct `zfs_slog_cache_confirm=true` flag.
- `install-post.env.sample` documents `XS_CEPH_FAIL_HARD` and explains when
  `XS_OVHRTM_SHA256` is needed.
- Removed the hardcoded macOS Homebrew Python path from `.vscode/settings.json`,
  which broke Linux contributors.

## [1.0.2] - 2026-02-22

### Fixed

- `pveceph install` hung under Ansible: `stdin: "Y\n"` does nothing because apt
  reads from `/dev/tty`. Replaced with `DEBIAN_FRONTEND=noninteractive`.
- The LXC Docker config had `lxc.kernel_modules: aufs ip_tables`, which is not
  valid in LXC 4.x and points at a filesystem that left the kernel in 5.15.
  Removed, and added `lxc.cgroup2.devices.allow: a` for cgroup v2 on PVE 8/9.
- Unanchored `grep -F` on the mount point corrupted `MY_LVM_DEV` when bind
  mounts were present. Replaced with `awk '$3 == mp'`.
- fstab cleanup deleted unrelated entries; now only lines whose mount point
  field matches exactly are removed, and comments are left alone.
- `community.general` was used by `proxmox_zfs_slog_cache` but never declared in
  `collections/requirements.yml`.
- `tinc-down` did `echo 0 > /proc/sys/net/ipv4/ip_forward`, which killed VM and
  container networking every time the VPN interface went down.
- Removed a duplicate `ip route add` from `tinc-up`; `ip addr add` already
  creates the connected route, so the second one always failed.
- The tinc service was enabled but never started.
- The `if-up.d` route script ran with `set -e`, so one bad route stopped network
  bringup. Per-route error handling instead.
- `parted print` aborts on a disk with no partition table, which killed
  `createzfs.sh` on fresh drives under `set -e`.
- An empty `readlink -f` result made the following `grep -qw` match everything.
- The PV device in `lvm-2-zfs.sh` was not checked to be an MD device.
- `tincvpn.sh -r` (reset) wrongly insisted on `-c`.
- `tincd -K4096` failures were silent when the public key existed but the
  private one did not.
- `MY_IFACE` was not checked after `udevadm` detection in the VNC installer.
- `debian13-2-proxmox9.sh` used the `'linux-image-6.*'` glob; replaced with an
  explicit `dpkg -l` list. (The Debian 12 script kept the glob until 1.0.4.)
- Molecule `test_sequence` had no `destroy` steps, so state accumulated between
  runs.
- Dropped the `mdadm --remove` task from the SLOG/cache role; it always fails
  after `--stop`.
- The subscription banner cron script and the APT hook used different sed
  patterns. Aligned.
- ZFS ARC MIN was MAX minus one byte in `install-post.sh`, which prevents the
  ARC from shrinking. Now 256MB/512MB up to 16GB RAM and 512MB/1GB up to 32GB.
- Comments said "11+ drives = raidz-3" while the code does 12+.
- `benchmark_zfs.sh` wrote ~20GB without checking it was on ZFS first.
- Tinc `Compression` was in the per-host file, where tincd ignores it.
- Tinc broadcast address was `0.0.0.0` instead of `10.10.1.255`.
- NVMe controller name extraction used `${dev::-2}`, which breaks on namespace
  numbers of 10 or more. Uses `${dev%%n[0-9]*}`.
- `hetzner/pve` and `hetzner/pbs` had no root check.
- `proxmox_repo_key_path` had no default value.

### Changed

- Removed `var-naming` from the ansible-lint skip list, so the documented naming
  convention is actually enforced.
- Debian 13 package fixes: `mlocate` replaced by `plocate`, `omping` and
  `software-properties-common` dropped (not available on Trixie).

## [1.0.1] - 2026-01-16

### Added

Ansible migration, finished. Every shell script now has a role behind it.

- Roles: `proxmox_base`, `proxmox_security`, `proxmox_tuning`, `proxmox_zfs`,
  `proxmox_vfio`, `proxmox_networking`, `provider_ovh`, `provider_hetzner`.
- `proxmox_zfs_slog_cache`: turns MD RAID devices into ZFS cache (L2ARC) and
  SLOG, using disk-by-id paths, behind `zfs_slog_cache_confirm: true`.
- `proxmox_tinc_vpn`: mesh VPN with 4096-bit RSA keys, systemd unit, public IP
  detection and host key distribution across nodes.
- `proxmox_lxc_docker`: Docker inside LXC, with the warning and an explicit
  confirmation flag.
- `proxmox_nvidia`: NVIDIA container runtime and Docker daemon config.
- Playbooks for all of the above plus `network-configure`, `lvm-to-zfs` and
  `zfs-create`.
- Molecule syntax checks.

Security work in the same release:

- Checksum variables for every remote download: `XS_INSTALL_POST_SHA256`,
  `XS_OVHRTM_SHA256`, `MY_POSTINSTALL_SHA256`, `PVE_EDGE_KERNEL_SHA256`.
- Confirmation flags for the destructive scripts: `LVM2ZFS_CONFIRM`,
  `LXC_DOCKER_CONFIRM`, `ZFS_CONFIRM`.
- Input validation: RFC 1123 hostnames and the 253 character limit in the
  installimage script, container IDs in `pve-enable-lxc-docker.sh`, IP addresses
  for timezone and OVH ASN detection, kernel version numbers, FQDN checks in the
  converters.
- GPG key checksum validation in the Ansible roles.

Shell script cleanup:

- `set -e` and `set -o pipefail` everywhere.
- Unreachable code removed from `installimage-proxmox.sh`.
- Unquoted variables fixed in `slog-cache-2-zfs.sh`.
- `run_cmd()` return code fixed for dry-run in `createzfs.sh`.
- Warning about the outdated default URL in `pve-edege-kernel.sh`.
- Cleanup added to the ERR trap in `install-post.sh`.
- `mktemp` for temporary files in `nvidia-docker.sh`.
- ZFS module load verification in `createzfs.sh`.

### Removed

- Proxmox VE 7.x and Debian 11 support, including `debian11-2-proxmox7.sh`.

### Fixed

- Kernel version comparison in `install-post.sh` mishandled 7.0.
- Variable quoting in the ZFS pool commands.
- Handler in `proxmox_nvidia` did not reload the daemon properly.
- `chmod 777` replaced with `755` in `installimage-proxmox.sh`.
- Unquoted `$MY_IFACE` in `vnc-install-proxmox.sh`.
- `tincvpn.sh` deleted the literal path `/etc/tinc/my_default_v4ip` on cleanup.
- Missing else branch for a 0 device pool in `createzfs.sh`.
- Race after `modprobe zfs` in `createzfs.sh`.
- Placeholder GPG checksum for Trixie now skips validation instead of failing.

## [1.0.0] - 2026-01-10

First release. Shell scripts only.

- `install-post.sh`, the post-installation optimizer.
- Debian to Proxmox conversion scripts for 11, 12 and 13.
- Hetzner and OVH provider support.
- ZFS scripts: `lvm-2-zfs.sh`, `createzfs.sh`, `slog-cache-2-zfs.sh`.
- Networking: `network-configure.sh`, `tincvpn.sh`.
- Helpers: `pve-enable-lxc-docker.sh`, `pve-edege-kernel.sh`.
- NVIDIA Docker support.

Supported: Proxmox VE 9.x (Trixie), 8.x (Bookworm), 7.x (Bullseye) and Proxmox
Backup Server 3.x.
