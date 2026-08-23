#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Fakes enough of a Proxmox host that a check-mode run reaches every task.
# Only for CI and local testing. Never run this on a real machine.
#
################################################################################
set -euo pipefail

if [ -f /etc/pve/.version ] && [ ! -f /etc/pve/.fixture ]; then
  echo "ERROR: /etc/pve/.version exists and was not created by this script."
  echo "       This looks like a real Proxmox host. Refusing to touch it."
  exit 1
fi

BIN=/usr/local/bin

# The apt module needs python3-apt even in check mode
if ! python3 -c 'import apt' 2>/dev/null; then
  echo "Installing python3-apt"
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-apt >/dev/null
fi

# contrib so packages like zfsutils-linux resolve. Edit the components in place
# rather than adding a second source: a duplicate entry without Signed-By makes
# apt refuse to read the list at all.
if [ -f /etc/apt/sources.list.d/debian.sources ] &&
   ! grep -q 'Components:.*contrib' /etc/apt/sources.list.d/debian.sources; then
  echo "Enabling contrib and non-free"
  sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' \
    /etc/apt/sources.list.d/debian.sources
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
elif [ -f /etc/apt/sources.list ] && ! grep -q 'contrib' /etc/apt/sources.list; then
  echo "Enabling contrib and non-free"
  sed -i 's/\(^deb .*main\)$/\1 contrib non-free/' /etc/apt/sources.list
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

echo "Creating /etc/pve"
mkdir -p /etc/pve/firewall /etc/pve/lxc /etc/pve/nodes
echo "8.3.0" > /etc/pve/.version
touch /etc/pve/.fixture

echo "Creating stub binaries in ${BIN}"

cat > "${BIN}/pveversion" <<'EOF'
#!/bin/sh
echo "pve-manager/8.3.0/abcdef1234567890 (running kernel: 6.8.12-4-pve)"
EOF

cat > "${BIN}/pveam" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${BIN}/pvesm" <<'EOF'
#!/bin/sh
# 'status --storage X' fails so the role thinks the storage is missing
case "$1" in
  status) exit 2 ;;
  *) exit 0 ;;
esac
EOF

cat > "${BIN}/pvesh" <<'EOF'
#!/bin/sh
case "$2" in
  /cluster/backup) echo "[]" ;;
  *) echo "{}" ;;
esac
EOF

cat > "${BIN}/pveum" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${BIN}/pveceph" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${BIN}/pct" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${BIN}/pve-firewall" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${BIN}/pve-efiboot-tool" <<'EOF'
#!/bin/sh
exit 0
EOF

# Containers have no systemd. The stub reports every unit as loaded, enabled and
# running, so service tasks report ok instead of failing. That means the fixture
# proves the tasks run and the templates render, not that anything really starts.
if ! command -v systemctl >/dev/null 2>&1; then
  cat > "${BIN}/systemctl" <<'EOF'
#!/bin/sh
case "${1:-}" in
  show)
    printf 'LoadState=loaded\nActiveState=active\nSubState=running\nUnitFileState=enabled\nUnitFilePreset=enabled\n'
    ;;
  is-active) echo active ;;
  is-enabled) echo enabled ;;
  *) : ;;
esac
exit 0
EOF
  chmod 0755 "${BIN}/systemctl"
fi

chmod 0755 \
  "${BIN}/pveversion" "${BIN}/pveam" "${BIN}/pvesm" "${BIN}/pvesh" \
  "${BIN}/pveum" "${BIN}/pveceph" "${BIN}/pct" "${BIN}/pve-firewall" \
  "${BIN}/pve-efiboot-tool"

# Files the roles edit with lineinfile/blockinfile, which need them to exist
mkdir -p /etc/apt/sources.list.d /etc/apt/keyrings /etc/default \
         /etc/security/limits.d /etc/modprobe.d /etc/network/interfaces.d \
         /etc/ssh/sshd_config.d /etc/systemd /etc/pam.d /etc/zfs/zed.d \
         /var/crash /root/.ssh

for f in /etc/network/interfaces /etc/vzdump.conf /etc/ksmtuned.conf \
         /etc/systemd/system.conf /etc/systemd/user.conf \
         /etc/systemd/journald.conf /etc/pam.d/common-session \
         /etc/pam.d/runuser-l /etc/logrotate.conf /etc/motd \
         /etc/aliases /root/.bashrc /root/.profile /root/.bash_profile; do
  [ -f "$f" ] || : > "$f"
done

[ -f /etc/default/grub ] || echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet"' > /etc/default/grub

echo "Fixture ready. Remove it with: rm -rf /etc/pve ${BIN}/pve*"
