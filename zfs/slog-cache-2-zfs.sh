#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# post-installation script for Proxmox
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Assumptions: /ashimov/zfs-cache and/or /ashimov/zfs-slog are mounted.
#
# Assumes mounted MD raid partitions (linux software raid)
#
# Usage:
# curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/zfs/slog-cache-2-zfs.sh && chmod +x slog-cache-2-zfs.sh
# ./slog-cache-2-zfs.sh MY_ZFS_POOL
#
# NOTES: remove slog with
#  zpool remove MYPOOL mirror-1
# NOTES: remove cache with
# zpool remove DEVICE
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

# Exit on error, pipe failures
set -e
set -o pipefail

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

MY_ZFS_POOL="$1"

if [ "$MY_ZFS_POOL" == "" ]; then
  #DEFAULT ZFS POOL
  MY_ZFS_POOL="hddpool"
fi

declare -a ZFS_MOUNTS=('/ashimov/zfs-cache' '/ashimov/zfs-slog');

echo "+++++++++++++++++++++++++"
echo "WILL DESTROY ALL DATA ON"
echo "${ZFS_MOUNTS[@]}"
echo "+++++++++++++++++++++++++"
echo "[CTRL]+[C] to exit"
echo "+++++++++++++++++++++++++"
sleep 1
echo "5.." ; sleep 1
echo "4.." ; sleep 1
echo "3.." ; sleep 1
echo "2.." ; sleep 1
echo "1.." ; sleep 1
echo "STARTING CONVERSION"
sleep 1

for ZFS_MOUNT_POINT in "${ZFS_MOUNTS[@]}" ; do
  echo "$ZFS_MOUNT_POINT"
  #check mountpiont exists and is a device
  ZFS_MOUNT_POINT_DEV=$(mount | awk -v mp="$ZFS_MOUNT_POINT" '$3 == mp {print $1; exit}' || true)
  if [ "$ZFS_MOUNT_POINT_DEV" != "" ] ; then
     echo "Found partition, continuing"
     echo "ZFS_MOUNT_POINT_DEV=$ZFS_MOUNT_POINT_DEV" #/dev/mapper/pve-data
  else
    echo "SKIPPING: $ZFS_MOUNT_POINT not found"
    continue
  fi

  #Detect and install dependencies
  if [ "$(command -v zpool)" == "" ] ; then
    if [ "$(command -v apt-get)" != "" ] ; then
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install zfsutils-linux
      modprobe zfs
    else
      echo "ERROR: ZFS not installed"
      exit 1
    fi
  fi
  if [ "$(command -v zpool)" == "" ] ; then
    echo "ERROR: ZFS not installed"
    exit 1
  fi
  if [ "$(command -v tune2fs)" == "" ] ; then
    echo "ERROR: tune2fs not installed"
    exit 1
  fi

  if ! zpool status "$MY_ZFS_POOL" 2> /dev/null ; then
    echo "ERROR: ZFS pool ${MY_ZFS_POOL} not found"
    exit 1
  fi

  ZFS_MOUNT_POINT_MD_RAID="${ZFS_MOUNT_POINT_DEV##*/}"
  if [[ ! "$ZFS_MOUNT_POINT_MD_RAID" =~ ^md[0-9]+$ ]]; then
    echo "ERROR: $ZFS_MOUNT_POINT_DEV does not appear to be an MD device (got: $ZFS_MOUNT_POINT_MD_RAID)"
    exit 1
  fi

  # "(auto-read-only)" shifts the columns, so match name[index] tokens
  mapfile -t mddevarray < <(grep -F "$ZFS_MOUNT_POINT_MD_RAID :" /proc/mdstat | grep -oE '[a-zA-Z0-9]+\[[0-9]+\]' || true)

  if [ "${#mddevarray[@]}" -eq 0 ] || [ "${mddevarray[0]}" == "" ] ; then
    echo "ERROR: no devices found for $ZFS_MOUNT_POINT_DEV in /proc/mdstat"
    exit 1
  fi
  #check there is a minimum of 1 drives detected, not needed, but i rather have it.
  if [ "${#mddevarray[@]}" -lt "1" ] ; then
    echo "ERROR: less than 1 devices were detected"
    exit 1
  fi

  # remove [*] and prefix /dev/ on each record
  echo "Creating the device array"
  for index in "${!mddevarray[@]}" ; do
      tempmddevarraystring="${mddevarray[index]}"
      mddevarray[index]="/dev/${tempmddevarraystring%%\[*}"
  done

  # Nothing to roll back to once the superblocks are zeroed
  for MY_MD_MEMBER in "${mddevarray[@]}" ; do
    if [ ! -b "$MY_MD_MEMBER" ] ; then
      echo "ERROR: parsed member '${MY_MD_MEMBER}' is not a block device - aborting before any destructive step"
      echo "Parsed members: ${mddevarray[*]}"
      exit 1
    fi
  done
  echo "Validated MD members: ${mddevarray[*]}"

  echo "Destroying MD (linux raid)"
  echo umount -f "${ZFS_MOUNT_POINT_DEV}"
  umount -f "${ZFS_MOUNT_POINT_DEV}"
  echo mdadm --stop "${ZFS_MOUNT_POINT_DEV}"
  mdadm --stop "${ZFS_MOUNT_POINT_DEV}"
  echo "Cleaning up fstab / mounts"
  fstab_tmp=$(mktemp /tmp/fstab.XXXXXX)
  trap 'rm -f "$fstab_tmp"' EXIT
  awk -v mp="$ZFS_MOUNT_POINT" '/^[[:space:]]*#/ { print; next } NF >= 2 && $2 == mp { next } { print }' /etc/fstab > "$fstab_tmp" && mv "$fstab_tmp" /etc/fstab

  MY_MD_DEV_PATHS=()
  for MY_MD_DEV in "${mddevarray[@]}" ; do
      echo "zeroing $MY_MD_DEV"
      echo mdadm --zero-superblock "$MY_MD_DEV"
      mdadm --zero-superblock "$MY_MD_DEV"
      MY_MD_DEV_PATH=""
      for MY_BY_ID in /dev/disk/by-id/*; do
        if [ "$(readlink -f "$MY_BY_ID")" == "$MY_MD_DEV" ] ; then
          MY_MD_DEV_PATH="$MY_BY_ID"
          break
        fi
      done
      if [ "$MY_MD_DEV_PATH" == "" ] ; then
        MY_MD_DEV_PATH="$MY_MD_DEV"
      fi
      MY_MD_DEV_PATHS+=("$MY_MD_DEV_PATH")
  done

  if [ "${#MY_MD_DEV_PATHS[@]}" -eq 0 ] ; then
    echo "ERROR: no usable device paths resolved for ${ZFS_MOUNT_POINT}"
    exit 1
  fi

  if [ "$ZFS_MOUNT_POINT" == "/ashimov/zfs-cache" ] ; then
    echo "Adding ${mddevarray[*]} to ${MY_ZFS_POOL} as CACHE"
    printf '%s\n' "${MY_MD_DEV_PATHS[@]}"
    zpool add "${MY_ZFS_POOL}" cache "${MY_MD_DEV_PATHS[@]}"
  elif [ "$ZFS_MOUNT_POINT" == "/ashimov/zfs-slog" ] ; then
    echo "Adding ${mddevarray[*]} to ${MY_ZFS_POOL} as SLOG"
    printf '%s\n' "${MY_MD_DEV_PATHS[@]}"
    if [ "${#mddevarray[@]}" -eq "1" ] ; then
      zpool add "${MY_ZFS_POOL}" log "${MY_MD_DEV_PATHS[@]}"
    else
      zpool add "${MY_ZFS_POOL}" log mirror "${MY_MD_DEV_PATHS[@]}"
    fi
  else
    echo "SKIPPING: Nothing todo with the partions"
    echo "${mddevarray[@]}"
    printf '%s\n' "${MY_MD_DEV_PATHS[@]}"
  fi
done

zpool iostat -v "$MY_ZFS_POOL" -L -T d


#script Finish
echo -e '\033[1;33m Finished....please restart the server \033[0m'
