#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
## CREATES A ROUTED vmbr0 NETWORK CONFIGURATION FOR PROXMOX
# Autodetects the correct settings (interface, gateway, netmask, etc)
# Supports IPv4 and IPv6
#
# ROUTED (vmbr0):
#   All traffic is routed via the main IP address and uses the MAC address
#   of the physical interface. VMs can have multiple IP addresses and they
#   do NOT require a MAC to be set for the IP via service provider.
#
# Tested on OVH and Hetzner based servers
#
# NOTE: WILL OVERWRITE /etc/network/interfaces
# A backup will be created as /etc/network/interfaces.timestamp
#
################################################################################

set -e
set -o pipefail

# Set the locale
export LANG="en_US.UTF-8"
export LC_ALL="C"

network_interfaces_file="/etc/network/interfaces"

# Validate IPv4 address (checks format and octet range 0-255)
validate_ipv4() {
  local ip="$1"
  if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi
  local IFS='.'
  read -r -a octets <<< "$ip"
  for octet in "${octets[@]}"; do
    if [[ "$octet" -gt 255 ]]; then
      return 1
    fi
  done
  return 0
}

# Create sysctl config for IP forwarding (for routed VMs)
if ! [ -f "/etc/sysctl.d/99-networking.conf" ]; then
  echo "Creating /etc/sysctl.d/99-networking.conf"
  cat > /etc/sysctl.d/99-networking.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv6.conf.all.forwarding=1
EOF
  sysctl --system
fi

get_bridge_port() {
  local bridge_name="$1"
  local port=""

  if [ -f /etc/network/interfaces ]; then
    port="$(awk -v br="$bridge_name" '
      $1=="iface" && $2==br {in_br=1; next}
      $1=="iface" {in_br=0}
      in_br && $1=="bridge_ports" {print $2; exit}
    ' /etc/network/interfaces)"
  fi

  if [ -z "$port" ] && command -v bridge >/dev/null 2>&1; then
    port="$(bridge link 2>/dev/null | awk -v br="$bridge_name" '$0 ~ "master " br {print $2; exit}' | sed 's/://')"
  fi

  if [ "$port" == "none" ]; then
    port=""
  fi

  echo "$port"
}

# Auto detect the existing network settings
echo "Auto detecting existing network settings"

# Detect primary interface using the default route
default_interface="$(ip -o route get 8.8.8.8 | grep -o 'dev [^ ]*' | xargs | cut -d' ' -f 2)"
default_ip_interface="$default_interface"

if [[ $default_interface == vmbr* ]] ; then
  bridge_port="$(get_bridge_port "$default_interface")"
  if [ "$bridge_port" == "" ] ; then
    echo "ERROR: Default route uses ${default_interface}, but no bridge port was detected"
    if ! command -v bridge >/dev/null 2>&1; then
      echo "ERROR: bridge command is not available to detect bridge ports"
    fi
    exit 1
  fi
  default_interface="$bridge_port"
fi

if [[ $default_interface == eth* ]] ; then
  # Search for the alt name, ie enp0s1 instead of eth0
  default_interface_altname="$(ip link show "${default_interface}" | grep -o 'altname [^ ]*' | xargs | cut -d' ' -f 2)"
  # Assign the alt name if present
  if [ -n "$default_interface_altname" ] && [ "$default_interface_altname" != " " ]; then
    default_interface="$default_interface_altname"
  fi
fi

if [ "$default_interface" == "" ]; then
  # Filter the interfaces to get the default interface
  default_interface="$(ip link | sed -e '/state DOWN / { N; d; }' | sed -e '/veth[0-9].*:/ { N; d; }' | sed -e '/vmbr[0-9].*:/ { N; d; }' | sed -e '/tap[0-9].*:/ { N; d; }' | sed -e '/lo:/ { N; d; }' | head -n 1 | cut -d':' -f 2 | xargs)"
  default_ip_interface="$default_interface"
fi

if [ "$default_interface" == "" ]; then
  echo "ERROR: Could not detect default interface"
  exit 1
fi

default_v4gateway="$(ip route | awk '/default/ { print $3 }')"
default_v4="$(ip -4 addr show dev "$default_ip_interface" | awk '/inet/ { print $2 }')"
default_v4ip=${default_v4%/*}
default_v4mask=${default_v4#*/}

if [ "$default_v4mask" == "$default_v4ip" ] ; then
  if ! command -v ifconfig >/dev/null 2>&1; then
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install net-tools
  fi
  default_v4netmask="$(ifconfig "$default_ip_interface" | awk '/netmask/ { print $4 }')"
else
  if [ "$default_v4mask" -lt "1" ] || [ "$default_v4mask" -gt "32" ] ; then
    echo "ERROR: Invalid CIDR $default_v4mask"
    exit 1
  fi
  cdr2mask () {
    local cidr="$1"
    # Validate CIDR is numeric and in range (already checked above, but defense in depth)
    if [[ ! "$cidr" =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
      echo "0.0.0.0"
      return 1
    fi
    set -- $(( 5 - (cidr / 8) )) 255 255 255 255 $(( (255 << (8 - (cidr % 8))) & 255 )) 0 0 0
    if [[ "$1" -gt 1 ]] ; then shift "$1" ; else shift ; fi ; echo "${1-0}.${2-0}.${3-0}.${4-0}"
  }
  default_v4netmask="$(cdr2mask "$default_v4mask")"
fi

# Validate detected values
if ! validate_ipv4 "$default_v4ip"; then
  echo "ERROR: Invalid IPv4 address detected: ${default_v4ip}"
  exit 1
fi
if ! validate_ipv4 "$default_v4gateway"; then
  echo "ERROR: Invalid IPv4 gateway detected: ${default_v4gateway}"
  exit 1
fi
if ! validate_ipv4 "$default_v4netmask"; then
  echo "ERROR: Invalid IPv4 netmask detected: ${default_v4netmask}"
  exit 1
fi

if [ "$default_v4ip" == "" ] || [ "$default_v4netmask" == "" ] || [ "$default_v4gateway" == "" ]; then
  echo "ERROR: Could not detect all IPv4 variables"
  echo "IP: ${default_v4ip} Netmask: ${default_v4netmask} Gateway: ${default_v4gateway}"
  exit 1
fi

echo "Detected: Interface=${default_interface} IP=${default_v4ip} Netmask=${default_v4netmask} Gateway=${default_v4gateway}"

# Backup existing config
cp "$network_interfaces_file" "${network_interfaces_file}.$(date +"%Y-%m-%d_%H-%M-%S")"

# Write new configuration
cat > "$network_interfaces_file" <<EOF
###### ashimov.com

### LOOPBACK ###
auto lo
iface lo inet loopback
iface lo inet6 loopback

### IPv4 ###
# Main IPv4 from Host
auto ${default_interface}
iface ${default_interface} inet manual

### VM-Bridge used by Proxmox (Routed)
auto vmbr0
iface vmbr0 inet static
  address ${default_v4ip}
  netmask ${default_v4netmask}
  gateway ${default_v4gateway}
  pointopoint ${default_v4gateway}
  bridge_ports ${default_interface}
  bridge_stp off
  bridge_fd 0
  bridge_maxwait 0

### Load extra files
source /etc/network/interfaces.d/*

EOF

# Detect and configure IPv6 if available
default_v6="$(ip -6 addr show dev "$default_ip_interface" | awk '/global/ { print $2}')"
default_v6ip=${default_v6%/*}
default_v6mask=${default_v6#*/}
default_v6gateway="$(ip -6 route | awk '/default/ { print $3 }')"

if [ "$default_v6ip" != "" ] && ! [[ "$default_v6ip" =~ : ]]; then
  echo "ERROR: Invalid IPv6 address detected: ${default_v6ip}"
  exit 1
fi
if [ "$default_v6gateway" != "" ] && ! [[ "$default_v6gateway" =~ : ]]; then
  echo "ERROR: Invalid IPv6 gateway detected: ${default_v6gateway}"
  exit 1
fi
if [ "$default_v6mask" != "" ] ; then
  if ! [[ "$default_v6mask" =~ ^[0-9]+$ ]] || [ "$default_v6mask" -lt 1 ] || [ "$default_v6mask" -gt 128 ]; then
    echo "ERROR: Invalid IPv6 prefix length detected: ${default_v6mask}"
    exit 1
  fi
fi

if [ "$default_v6ip" != "" ] && [ "$default_v6mask" != "" ] && [ "$default_v6gateway" != "" ]; then
  echo "Detected IPv6: ${default_v6ip}/${default_v6mask} Gateway=${default_v6gateway}"
  cat >> "$network_interfaces_file" << EOF
### IPv6 ###
iface vmbr0 inet6 static
  address ${default_v6ip}
  netmask ${default_v6mask}
  gateway ${default_v6gateway}

EOF
fi

echo -e '\033[1;33m Finished....please restart the system \033[0m'
