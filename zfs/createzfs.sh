#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# Will create a ZFS pool from the devices specified with the correct raid level
#
# Note: compatible with all debian based distributions
# If proxmox is detected, it will add the pools to the storage system
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Creates the following storage/rpools
# poolnamebackup (poolname/backup)
# poolnamevmdata (poolname/vmdata)
#
# zfs-auto-snapshot is disabled on the backup (poolname/backup)
#
# Will automatically detect the required raid level and optimise.
#
# Will automatically resolve device names (eg. /dev/sda) to device id (eg. SSD1_16261489FFCA)
#
# 1 Drive = zfs
# 2 Drives = mirror
# 3-5 Drives = raidz-1
# 6-11 Drives = raidz-2
# 12+ Drives = raidz-3
#
# NOTE: WILL  DESTROY ALL DATA ON DEVICES SPECIFED
#
# Usage:
# curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/zfs/createzfs.sh && chmod +x createzfs.sh
# ZFS_CONFIRM=yes ./createzfs.sh poolname /dev/sda /dev/sdb
# ZFS_DRYRUN=yes ./createzfs.sh poolname /dev/sda /dev/sdb
#
################################################################################
#
#    THERE ARE  USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#   ALL CONFIGURATION OPTIONS ARE LOCATED BELOW THIS MESSAGE
#
##############################################################

#/dev/md3              4.9G   20M  4.6G   1% /xshok/zfs-slog
#/dev/md2               59G   53M   56G   1% /xshok/zfs-cache

# Exit on error, pipe failures
set -e
set -o pipefail

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

ZFS_CONFIRM="${ZFS_CONFIRM:-no}"
ZFS_DRYRUN="${ZFS_DRYRUN:-no}"

run_cmd() {
  if [ "${ZFS_DRYRUN,,}" == "yes" ] ; then
    echo "DRY-RUN: $*"
    return 0
  else
    "$@"
  fi
}

poolname=${1}
zfsdevicearray=("${@:2}")

#Detect and install dependencies
if ! type "zpool" >& /dev/null; then
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install zfsutils-linux
  modprobe zfs
fi
if ! type "parted" >& /dev/null; then
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install parted
fi

#check arguments
if [ $# -lt "2" ] ; then
  echo "Usage: $(basename "$0") poolname /list/of /dev/device1 /dev/device2"
  echo "Note will append 'pool' to the poolname, eg. hdd -> hddpool"
  echo "Will automatically resolve device names (eg. /dev/sda) to device id (eg. SSD1_16261489FFCA)"
  echo "Device names, /dev/disk/by-id"
  # shellcheck disable=2010
  ls -l /dev/disk/by-id/ | grep -v "\\-part*" | grep -v "wwn\\-*" | grep -v "usb\\-*" | cut -d" " -f10-20 | sed 's|../../|/dev/|' | awk NF
  exit 1
fi
if [[ "$poolname" =~ "/" ]] ; then
  echo "ERROR: invalid poolname: $poolname"
  exit 1
fi
if [[ ! "$poolname" =~ ^[a-zA-Z][a-zA-Z0-9_:.-]*$ ]]; then
  echo "ERROR: Pool name '$poolname' contains invalid characters"
  exit 1
fi
if [ "${#zfsdevicearray[@]}" -lt "1" ] ; then
  echo "ERROR: less than 1 devices were detected"
  exit 1
fi

if [ "${ZFS_DRYRUN,,}" != "yes" ] && [ "${ZFS_CONFIRM,,}" != "yes" ] ; then
  echo "ERROR: This script is destructive. Re-run with ZFS_CONFIRM=yes to continue."
  exit 1
fi
if [ "${ZFS_DRYRUN,,}" == "yes" ] ; then
  echo "DRY-RUN: no changes will be made"
fi

#add the suffix pool to the poolname, prevent namepoolpool
poolprefix=${poolname/pool/}
poolname="${poolprefix}pool"

INDEX=0
for zfsdevice in "${zfsdevicearray[@]}" ; do
  if ! [[ "$zfsdevice" =~ "/" ]] ; then
    if ! [[ "$zfsdevice" =~ "-" ]] ; then
      echo "ERROR: Invalid device specified: $zfsdevice"
      exit 1
    fi
  fi
  if ! [ -e "$zfsdevice" ]; then
    if ! [ -e "/dev/disk/by-id/$zfsdevice" ]; then
      if ! [ -e "/dev/disk/by-uuid/$zfsdevice" ]; then
        echo "ERROR: Device $zfsdevice does not exist"
        exit 1
      fi
    fi
  fi
  resolved_dev=$(readlink -f "$zfsdevice")
  if [ -z "$resolved_dev" ]; then
    echo "ERROR: Cannot resolve device path for $zfsdevice"
    exit 1
  fi
  if grep -qw "$resolved_dev" "/proc/mounts" ; then
    echo "ERROR: Device is mounted $zfsdevice"
    exit 1
  fi
  echo "Clearing partitions: ${zfsdevice}"
  for v_partition in $(parted -s "${zfsdevice}" print 2>/dev/null | awk '/^ / {print $1}' || true) ; do
    run_cmd parted -s "${zfsdevice}" rm "${v_partition}" 2> /dev/null
  done

  if [[ "$zfsdevice" =~ "/" ]] ; then
    if [[ "$zfsdevice" == /dev/disk/by-id/* ]] ; then
      MY_DEV="${zfsdevice##*/}"
    else
      MY_DEV=""
      for id_path in /dev/disk/by-id/* ; do
        [ -L "$id_path" ] || continue
        if [ "$(readlink -f "$id_path")" == "$zfsdevice" ] ; then
          MY_DEV="${id_path##*/}"
          if [[ "$MY_DEV" != *-part* ]] ; then
            break
          fi
        fi
      done
    fi
    if [ -n "$MY_DEV" ] && [ -e "/dev/disk/by-id/${MY_DEV}" ]; then
      echo "${zfsdevice} -> ${MY_DEV}"
      #replace current value
      zfsdevicearray[$INDEX]="${MY_DEV}"
    else
      echo "WARNING: Unable to resolve ${zfsdevice} to /dev/disk/by-id; using original path"
    fi
  fi
  INDEX=$((INDEX + 1))
done

echo "Enable ZFS to autostart and mount"
run_cmd systemctl enable zfs.target
run_cmd systemctl enable zfs-mount
run_cmd systemctl enable zfs-import-cache

echo "Ensure ZFS is started"
run_cmd systemctl start zfs.target
run_cmd modprobe zfs
# Wait for ZFS module to fully initialize
sleep 1

# Verify ZFS module loaded successfully
if [ "${ZFS_DRYRUN,,}" != "yes" ]; then
  if ! lsmod | grep -q "^zfs "; then
    echo "ERROR: ZFS kernel module failed to load"
    exit 1
  fi
fi

importable_pools=$(zpool import 2>/dev/null || true)
if echo "$importable_pools" | grep -qw "$poolname"; then
  echo "ERROR: $poolname already exists as an exported pool"
  echo "$importable_pools"
  exit 1
fi
if zpool list -H -o name 2>/dev/null | grep -qx "$poolname"; then
  echo "ERROR: $poolname already exists as a listed pool"
  zpool list
  exit 1
fi

echo "Creating the array"
ret=0
if [ "${#zfsdevicearray[@]}" -eq "1" ] ; then
  echo "Creating ZFS single"
  run_cmd zpool create -f -o ashift=12 -O compression=lz4 -O checksum=on "$poolname" "${zfsdevicearray[@]}" || ret=$?
elif [ "${#zfsdevicearray[@]}" -eq "2" ] ; then
  echo "Creating ZFS mirror (raid1)"
  run_cmd zpool create -f -o ashift=12 -O compression=lz4 -O checksum=on "$poolname" mirror "${zfsdevicearray[@]}" || ret=$?
elif [ "${#zfsdevicearray[@]}" -ge "3" ] && [ "${#zfsdevicearray[@]}" -le "5" ] ; then
  echo "Creating ZFS raidz-1 (raid5)"
  run_cmd zpool create -f -o ashift=12 -O compression=lz4 -O checksum=on "$poolname" raidz "${zfsdevicearray[@]}" || ret=$?
elif [ "${#zfsdevicearray[@]}" -ge "6" ] && [ "${#zfsdevicearray[@]}" -le "11" ] ; then
  echo "Creating ZFS raidz-2 (raid6)"
  run_cmd zpool create -f -o ashift=12 -O compression=lz4 -O checksum=on "$poolname" raidz2 "${zfsdevicearray[@]}" || ret=$?
elif [ "${#zfsdevicearray[@]}" -ge "12" ] ; then
  echo "Creating ZFS raidz-3 (raid7)"
  run_cmd zpool create -f -o ashift=12 -O compression=lz4 -O checksum=on "$poolname" raidz3 "${zfsdevicearray[@]}" || ret=$?
else
  echo "ERROR: No valid disk configuration (0 devices found)"
  exit 1
fi

if [ "$ret" != 0 ] ; then
  echo "ERROR: creating ZFS (exit code: $ret)"
  exit 1
fi

if [ "${ZFS_DRYRUN,,}" == "yes" ] ; then
  echo "DRY-RUN: createzfs completed without changes"
  exit 0
fi

if ! zpool list -H -o name 2>/dev/null | grep -qx "$poolname"; then
  echo "ERROR: $poolname pool not found after creation"
  zpool list
  exit 1
fi

echo "Creating Secondary ZFS volumes"
echo "-- ${poolname}/vmdata"
run_cmd zfs create "${poolname}/vmdata"
echo "-- ${poolname}/backup (/backup_${poolprefix})"
run_cmd zfs create -o mountpoint="/backup_${poolprefix}" "${poolname}/backup"

#export the pool
run_cmd zpool export "${poolname}"
if [ "${ZFS_DRYRUN,,}" != "yes" ] ; then
  sleep 10
fi
run_cmd zpool import "${poolname}"
if [ "${ZFS_DRYRUN,,}" != "yes" ] ; then
  sleep 5
fi

echo "Optimising ${poolname}"
run_cmd zfs set compression=on "${poolname}"
run_cmd zfs set compression=lz4 "${poolname}"
run_cmd zfs set primarycache=all "${poolname}"
run_cmd zfs set atime=off "${poolname}"
run_cmd zfs set relatime=off "${poolname}"
run_cmd zfs set checksum=on "${poolname}"
run_cmd zfs set dedup=off "${poolname}"
run_cmd zfs set xattr=sa "${poolname}"

# disable zfs-auto-snapshot on backup pools
run_cmd zfs set com.sun:auto-snapshot=false "${poolname}/backup"

#check we do not already have a cron for zfs
if [ "${ZFS_DRYRUN,,}" != "yes" ] ; then
  if [ ! -f "/etc/cron.d/zfsutils-linux" ] ; then
    if [ -f /usr/lib/zfs-linux/scrub ] ; then
      cat <<'EOF' > /etc/cron.d/zfsutils-linux
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Scrub the pool every second Sunday of every month.
24 0 8-14 * * root [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/scrub ] && /usr/lib/zfs-linux/scrub
EOF
    else
      echo "Scrub the pool every second Sunday of every month ${poolname}"
      if [ ! -f "/etc/cron.d/zfs-scrub" ] ; then
        echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"  > "/etc/cron.d/zfs-scrub"
      fi
      echo "24 0 8-14 * * root [ \$(date +\\%w) -eq 0 ] && zpool scrub ${poolname}" >> "/etc/cron.d/zfs-scrub"
    fi
  fi
else
  echo "DRY-RUN: skipping cron configuration"
fi

# pvesm (proxmox) is optional
if type "pvesm" >& /dev/null; then
  # https://pve.proxmox.com/pve-docs/pvesm.1.html
  echo "Adding the ZFS storage pools to Proxmox GUI"
  echo "-- ${poolname}-vmdata"
  run_cmd pvesm add zfspool "${poolname}-vmdata" --pool "${poolname}/vmdata" --sparse 1
  echo "-- ${poolname}-backup"
  run_cmd pvesm add dir "${poolname}-backup" --path "/backup_${poolprefix}"
fi

### Work in progress , create specialised pools ###
# echo "ZFS 8GB swap partition"
# zfs create -V 8G -b $(getconf PAGESIZE) -o logbias=throughput -o sync=always -o primarycache=metadata -o com.sun:auto-snapshot=false "$poolname"/swap
# mkswap -f /dev/zvol/"$poolname"/swap
# swapon /dev/zvol/"$poolname"/swap
# /dev/zvol/"$poolname"/swap none swap discard 0 0
#
# echo "ZFS tmp partition"
# zfs create -o setuid=off -o devices=off -o sync=disabled -o mountpoint=/tmp -o atime=off "$poolname"/tmp
## note: if you want /tmp on ZFS, mask (disable) systemd's automatic tmpfs-backed /tmp
# systemctl mask tmp.mount
#
# echo "RDBMS partition (MySQL/PostgreSQL/Oracle)"
# zfs create -o recordsize=8K -o primarycache=metadata -o mountpoint=/rdbms -o logbias=throughput "$poolname"/rdbms

zpool iostat -v "${poolname}" -L -T d

#script Finish
echo -e '\033[1;33m Finished....please restart the server \033[0m'
