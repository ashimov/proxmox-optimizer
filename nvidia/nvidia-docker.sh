#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Installs the NVIDIA Container Toolkit so Docker can use the host GPU.
#
# The old nvidia-docker2 repo is EOL and has nothing for Debian 12/13, so this
# uses libnvidia-container, which is not per-distribution.
#
# License: BSD (Berkeley Software Distribution)
################################################################################
set -euo pipefail

# Reboot after installation
NVIDIA_DOCKER_REBOOT="${NVIDIA_DOCKER_REBOOT:-no}"
# Repository and key locations (override to use an internal mirror)
NVIDIA_TOOLKIT_GPG_URL="${NVIDIA_TOOLKIT_GPG_URL:-https://nvidia.github.io/libnvidia-container/gpgkey}"
NVIDIA_TOOLKIT_LIST_URL="${NVIDIA_TOOLKIT_LIST_URL:-https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list}"
# Optional pinned SHA256 of the signing key and the repository list.
# Empty = trust TLS only (a warning is printed).
NVIDIA_TOOLKIT_GPG_SHA256="${NVIDIA_TOOLKIT_GPG_SHA256:-}"
NVIDIA_TOOLKIT_LIST_SHA256="${NVIDIA_TOOLKIT_LIST_SHA256:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

verify_sha256() {
  local file="$1" expected="$2" name="$3"
  if [ "$expected" == "" ]; then
    echo "WARNING: no SHA256 pinned for ${name}; trusting TLS only"
    return 0
  fi
  if ! echo "${expected}  ${file}" | sha256sum -c - >/dev/null; then
    echo "ERROR: SHA256 verification failed for ${name}"
    return 1
  fi
  echo "Verified SHA256 for ${name}"
  return 0
}

if ! command -v gpg >/dev/null 2>&1; then
  apt-get update
  apt-get install -y gnupg
fi
if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl ca-certificates
fi

mkdir -p /usr/share/keyrings

# Create temporary files securely
nvidia_gpgkey_tmp="$(mktemp -t nvidia-gpgkey.XXXXXX)"
nvidia_list_tmp="$(mktemp -t nvidia-list.XXXXXX)"
trap 'rm -f "$nvidia_gpgkey_tmp" "$nvidia_list_tmp"' EXIT

# Download and install the NVIDIA signing key
if ! curl -fsSL --max-time 30 --retry 3 "$NVIDIA_TOOLKIT_GPG_URL" -o "$nvidia_gpgkey_tmp"; then
  echo "ERROR: Failed to download the NVIDIA signing key from ${NVIDIA_TOOLKIT_GPG_URL}"
  exit 1
fi
verify_sha256 "$nvidia_gpgkey_tmp" "$NVIDIA_TOOLKIT_GPG_SHA256" "NVIDIA container toolkit key"
gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg < "$nvidia_gpgkey_tmp"
chmod 0644 /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add the repository, forcing signed-by onto every deb line
if ! curl -fsSL --max-time 30 --retry 3 "$NVIDIA_TOOLKIT_LIST_URL" -o "$nvidia_list_tmp"; then
  echo "ERROR: Failed to download the NVIDIA repository list from ${NVIDIA_TOOLKIT_LIST_URL}"
  exit 1
fi
verify_sha256 "$nvidia_list_tmp" "$NVIDIA_TOOLKIT_LIST_SHA256" "NVIDIA container toolkit repository list"
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  "$nvidia_list_tmp" > /etc/apt/sources.list.d/nvidia-container-toolkit.list
chmod 0644 /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Remove the end-of-life nvidia-docker repository if a previous run added it
rm -f /etc/apt/sources.list.d/nvidia-docker.list /etc/apt/keyrings/nvidia-docker.gpg

apt-get update
apt-get install -y nvidia-container-toolkit

# Wire the runtime into Docker and reload the daemon
if command -v nvidia-ctk >/dev/null 2>&1; then
  nvidia-ctk runtime configure --runtime=docker
fi
if systemctl is-active --quiet docker; then
  systemctl restart docker
elif pgrep -x dockerd >/dev/null 2>&1; then
  pkill -SIGHUP dockerd
fi

if [ "${NVIDIA_DOCKER_REBOOT,,}" == "yes" ] || [ "${NVIDIA_DOCKER_REBOOT,,}" == "true" ]; then
  echo "Rebooting as requested (NVIDIA_DOCKER_REBOOT=${NVIDIA_DOCKER_REBOOT})"
  reboot
else
  echo "Installation complete. A reboot is recommended if the NVIDIA kernel module was just installed."
  echo "Set NVIDIA_DOCKER_REBOOT=yes to reboot automatically."
fi
