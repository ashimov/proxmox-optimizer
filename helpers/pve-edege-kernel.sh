#!/usr/bin/env bash
set -euo pipefail

# Install PVE-Edge-Kernel
# WARNING: The default URL points to an older kernel version (5.11.0-2).
# Check https://github.com/fabianishere/pve-edge-kernel/releases for newer versions.
# Override with PVE_EDGE_KERNEL_URL environment variable.
PVE_EDGE_KERNEL_URL="${PVE_EDGE_KERNEL_URL:-https://github.com/fabianishere/pve-edge-kernel/releases/download/v5.11.0-2/pve-edge-kernel-5.11.0-2_5.11.0-2+zen21_amd64.deb}"

echo "NOTE: Using PVE-Edge-Kernel from: ${PVE_EDGE_KERNEL_URL}"
echo "Check https://github.com/fabianishere/pve-edge-kernel/releases for newer versions."
echo ""
PVE_EDGE_KERNEL_DEB="${PVE_EDGE_KERNEL_URL##*/}"
PVE_EDGE_KERNEL_SHA256="${PVE_EDGE_KERNEL_SHA256:-}"
PVE_EDGE_KERNEL_ALLOW_UNVERIFIED="${PVE_EDGE_KERNEL_ALLOW_UNVERIFIED:-no}"

if ! wget -q --timeout=60 --tries=3 "$PVE_EDGE_KERNEL_URL" -O "$PVE_EDGE_KERNEL_DEB"; then
  echo "ERROR: Failed to download PVE edge kernel from ${PVE_EDGE_KERNEL_URL}"
  exit 1
fi

if [ -n "$PVE_EDGE_KERNEL_SHA256" ]; then
  if ! echo "${PVE_EDGE_KERNEL_SHA256}  ${PVE_EDGE_KERNEL_DEB}" | sha256sum -c -; then
    echo "ERROR: Checksum verification failed"
    rm -f "$PVE_EDGE_KERNEL_DEB"
    exit 1
  fi
elif [ "${PVE_EDGE_KERNEL_ALLOW_UNVERIFIED,,}" != "yes" ] && [ "${PVE_EDGE_KERNEL_ALLOW_UNVERIFIED,,}" != "true" ]; then
  echo "ERROR: PVE_EDGE_KERNEL_SHA256 not set; refusing to install unverified kernel"
  rm -f "$PVE_EDGE_KERNEL_DEB"
  exit 1
else
  echo "WARNING: Installing PVE edge kernel without checksum verification"
fi

/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get install -y "$(pwd)/$PVE_EDGE_KERNEL_DEB"
rm -f "$PVE_EDGE_KERNEL_DEB"
