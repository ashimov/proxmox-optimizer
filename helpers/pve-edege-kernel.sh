#!/usr/bin/env bash
set -euo pipefail

# Install PVE-Edge-Kernel
PVE_EDGE_KERNEL_URL="${PVE_EDGE_KERNEL_URL:-https://github.com/fabianishere/pve-edge-kernel/releases/download/v5.11.0-2/pve-edge-kernel-5.11.0-2_5.11.0-2+zen21_amd64.deb}"
PVE_EDGE_KERNEL_DEB="${PVE_EDGE_KERNEL_URL##*/}"

wget -q "$PVE_EDGE_KERNEL_URL" -O "$PVE_EDGE_KERNEL_DEB"
apt install -y "./$PVE_EDGE_KERNEL_DEB"
