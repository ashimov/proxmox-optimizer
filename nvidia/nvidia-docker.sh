#!/bin/bash
# thanks @88plug
set -e

if ! command -v gpg >/dev/null 2>&1; then
  apt-get update
  apt-get install -y gnupg
fi

distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
mkdir -p /etc/apt/keyrings
curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nvidia-docker.gpg
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sed 's#^deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-docker.gpg] https://#' | \
  tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update

# Install nvidia-docker2 and reload the Docker daemon configuration
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd

reboot
