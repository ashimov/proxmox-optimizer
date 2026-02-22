#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# Configures an LXC container to correctly support/run docker
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Note:
# There can be security implications as the LXC container is running in a higher privileged mode.
# Not advisable to run docker inside a LXC container.
# Correct way is to create a VM (qemu/kvm) which will be used exclusively for docker.
# ie. fresh ubuntu lts server with https://github.com/ashimov/ashimov-docker
#
# Usage:
# curl https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/helpers/pve-enable-lxc-docker.sh --output /usr/sbin/pve-enable-lxc-docker && chmod +x /usr/sbin/pve-enable-lxc-docker
# pve-enable-lxc-docker container_id
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
##############################################################

set -e
set -o pipefail

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

container_id="$1"

# Validate container ID
if [ -z "$container_id" ]; then
  echo "ERROR: Container ID is required"
  echo "Usage: $0 <container_id>"
  exit 1
fi

# Container ID must be numeric (Proxmox uses numeric IDs)
if ! [[ "$container_id" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Invalid container ID. Must be numeric."
  exit 1
fi

# Proxmox container IDs are typically 100-999999999
if [ "$container_id" -lt 100 ] || [ "$container_id" -gt 999999999 ]; then
  echo "ERROR: Container ID out of valid range (100-999999999)"
  exit 1
fi

container_config="/etc/pve/lxc/$container_id.conf"

# Security Warning
echo "================================================================================"
echo "  SECURITY WARNING: Running Docker in LXC Container"
echo "================================================================================"
echo ""
echo "  This script will configure the LXC container to run Docker by:"
echo "    - Disabling AppArmor confinement (lxc.apparmor.profile: unconfined)"
echo "    - Allowing access to all devices (lxc.cgroup.devices.allow: a)"
echo "    - Dropping no capabilities (lxc.cap.drop: empty)"
echo "    - Loading kernel modules (aufs, ip_tables)"
echo "    - Mounting proc and sys as read-write"
echo ""
echo "  RISKS:"
echo "    - Container escape vulnerabilities become more severe"
echo "    - Compromised container could affect host system"
echo "    - Not recommended for production or multi-tenant environments"
echo ""
echo "  RECOMMENDATION:"
echo "    Use a dedicated VM (QEMU/KVM) for Docker workloads instead."
echo "    See: https://github.com/ashimov/ashimov-docker"
echo ""
echo "================================================================================"
echo ""

# Require explicit confirmation unless LXC_DOCKER_CONFIRM is set
if [ "${LXC_DOCKER_CONFIRM:-}" != "yes" ]; then
  echo "To proceed, run with LXC_DOCKER_CONFIRM=yes:"
  echo "  LXC_DOCKER_CONFIRM=yes $0 $container_id"
  echo ""
  exit 1
fi

echo "Confirmation received. Proceeding with configuration..."
echo ""

function addlineifnotfound { #$file #$line
  if [ "$1" == "" ] || [ "$2" == "" ] ; then
    echo "Error missing parameters"
    exit 1
  else
    filename="$1"
    linecontent="$2"
  fi
  if [ ! -f "$filename" ] ; then
    echo "Error $filename not found"
    exit 1
  fi
  if ! grep -Fxq "$linecontent" "$filename" ; then
    #echo "\"$linecontent\" ---> $filename"
    echo "$linecontent" >> "$filename"
  fi
}

#add cgroups support
if [ "$(command -v cgroupfs-mount)" == "" ] ; then
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install cgroupfs-mount
fi

if [ -f "$container_config" ]; then

  addlineifnotfound "$container_config" "lxc.apparmor.profile: unconfined"
  addlineifnotfound "$container_config" "lxc.cgroup.devices.allow: a"
  addlineifnotfound "$container_config" "lxc.cgroup2.devices.allow: a"
  addlineifnotfound "$container_config" "lxc.cap.drop:"
  addlineifnotfound "$container_config" "lxc.mount.auto: proc:rw sys:rw"

  #pve is missing the lxc binary
  #lxc config set "$container_id" security.nesting true
  #lxc config set "$container_id" security.privileged true
  #lxc restart "$container_id"

  #pve lxc container restart (use Proxmox native pct commands)
  pct stop "$container_id"
  pct start "$container_id"

  echo "Docker support added to $container_id"

else
  echo "Error: Config $container_config could not be found"
  exit 1
fi
