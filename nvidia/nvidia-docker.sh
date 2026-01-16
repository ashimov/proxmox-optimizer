#!/bin/bash
# thanks @88plug
set -euo pipefail

NVIDIA_DOCKER_REBOOT="${NVIDIA_DOCKER_REBOOT:-yes}"

if ! command -v gpg >/dev/null 2>&1; then
  apt-get update
  apt-get install -y gnupg
fi

# shellcheck disable=SC1091
distribution=$(. /etc/os-release; echo "${ID}${VERSION_ID}")
mkdir -p /etc/apt/keyrings

# Create temporary files securely
nvidia_gpgkey_tmp=$(mktemp)
nvidia_list_tmp=$(mktemp)
trap 'rm -f "$nvidia_gpgkey_tmp" "$nvidia_list_tmp"' EXIT

# Download and install NVIDIA GPG key
if ! curl -fsSL --max-time 30 --retry 3 https://nvidia.github.io/nvidia-docker/gpgkey -o "$nvidia_gpgkey_tmp"; then
  echo "ERROR: Failed to download NVIDIA GPG key"
  exit 1
fi
gpg --dearmor -o /etc/apt/keyrings/nvidia-docker.gpg < "$nvidia_gpgkey_tmp"

# Add NVIDIA repository
if ! curl -fsSL --max-time 30 --retry 3 "https://nvidia.github.io/nvidia-docker/${distribution}/nvidia-docker.list" -o "$nvidia_list_tmp"; then
  echo "ERROR: Failed to download NVIDIA repository list"
  exit 1
fi
sed 's#^deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-docker.gpg] https://#' "$nvidia_list_tmp" > /etc/apt/sources.list.d/nvidia-docker.list

apt-get update

# Install nvidia-docker2 and reload the Docker daemon configuration
apt-get install -y nvidia-docker2
if pgrep -x dockerd >/dev/null 2>&1; then
  pkill -SIGHUP dockerd
fi

if [ "${NVIDIA_DOCKER_REBOOT,,}" == "yes" ]; then
  reboot
else
  echo "Skipping reboot (NVIDIA_DOCKER_REBOOT=${NVIDIA_DOCKER_REBOOT})"
fi
