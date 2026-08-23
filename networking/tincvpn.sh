#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# tinc vpn - installation script for Proxmox, Debian, CentOS and RedHat based servers
#
# License: BSD (Berkeley Software Distribution)
#
# Usage:
# curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/v1.0.4/networking/tincvpn.sh && chmod +x tincvpn.sh
# ./tincvpn.sh -h
#
# Example for 3 node Cluster
#
# cat /etc/hosts
# global ips for tinc servers
# 11.11.11.11 host1
# 22.22.22.22 host2
# 33.33.33.33 host3
#
# First Host (hostname: host1)
# ./tincvpn.sh -i 1 -c host2
# Second Host (hostname: host2)
# ./tincvpn.sh -i 2 -c host3
# Third Host (hostname: host3)
# ./tincvpn.sh -3 -c host1
#
#
################################################################################
#
#    THERE ARE  USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#   ALL CONFIGURATION OPTIONS ARE LOCATED BELOW THIS MESSAGE
#
##############################################################

set -e
set -o pipefail

# Require root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

vpn_ip_last=1
vpn_connect_to=""
vpn_port=655
my_default_v4ip=""
reset="no"
uninstall="no"

while getopts i:p:c:a:ruh option
do
  case "${option}"
      in
    i) vpn_ip_last=${OPTARG} ;;
    p) vpn_port=${OPTARG} ;;
    c) vpn_connect_to=${OPTARG} ;;
    a) my_default_v4ip=${OPTARG} ;;
    r) reset="yes" ;;
    u) uninstall="yes" ;;
    *) echo "-i <last_ip_part 10.10.1.?> -p <vpn port if not 655> -c <vpn host to connect to, eg. prx_b> -a <public ip address, or will auto-detect> -r (reset) -u (uninstall)" ; exit ;;
  esac
done

# These all end up in tinc.conf or hosts/*, a newline would add directives
if ! [[ "$vpn_ip_last" =~ ^[0-9]+$ ]] || [ "$vpn_ip_last" -lt 1 ] || [ "$vpn_ip_last" -gt 254 ]; then
  echo "ERROR: -i value must be a number between 1 and 254"
  exit 1
fi
if ! [[ "$vpn_port" =~ ^[0-9]+$ ]] || [ "$vpn_port" -lt 1 ] || [ "$vpn_port" -gt 65535 ]; then
  echo "ERROR: -p value must be a port number between 1 and 65535"
  exit 1
fi
if [ "$vpn_connect_to" != "" ] && ! [[ "$vpn_connect_to" =~ ^[a-zA-Z0-9_]{1,64}$ ]]; then
  echo "ERROR: -c must be a tinc node name ([a-zA-Z0-9_], max 64 chars)"
  exit 1
fi
if [ "$my_default_v4ip" != "" ] && ! [[ "$my_default_v4ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "ERROR: -a must be an IPv4 address"
  exit 1
fi

if [ "$reset" == "yes" ] || [ "$uninstall" == "yes" ] ; then
  echo "Stopping Tinc"
  systemctl stop tinc-pvemesh.service || true
  pkill -9 tincd || true

  echo "Removing configs"
  rm -rf /etc/tinc/pvemesh
  rm -f /etc/network/interfaces.d/tinc-vpn.cfg
  rm -f /etc/systemd/system/tinc-pvemesh.service

  if [ "$uninstall" == "yes" ] ; then
    systemctl disable tinc-pvemesh.service || true
    echo "Tinc uninstalled"
    exit 0
  fi
fi

if [ "$(command -v tinc)" == "" ] ; then
  if [ "$(command -v apt-get)" != "" ] ; then
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install tinc
  else
    echo "ERROR: tinc not installed"
    exit 1
  fi
fi


if [ "$my_default_v4ip" == "" ] ; then
  #detect default ipv4 and default interface
  default_interface="$(ip route | awk '/default/ { print $5; exit }' | grep -v "vmbr" || true)"
  if [ "$default_interface" == "" ]; then
    #filter the interfaces to get the default interface and which is not down and not a virtual bridge
    default_interface="$(ip link | sed -e '/state DOWN / { N; d; }' | sed -e '/veth[0-9].*:/ { N; d; }' | sed -e '/vmbr[0-9].*:/ { N; d; }' | sed -e '/tap[0-9].*:/ { N; d; }' | sed -e '/lo:/ { N; d; }' | head -n 1 | cut -d':' -f 2 | xargs)"
  fi
  if [ "$default_interface" == "" ]; then
    echo "ERROR: Could not detect default interface"
    exit 1
  fi
  default_v4="$(ip -4 addr show dev "$default_interface" | awk '/inet/ { print $2 }' )"
  my_default_v4ip=${default_v4%/*}
  if [ "$my_default_v4ip" == "" ] ; then
    echo "ERROR: Could not detect default IPv4 address"
    echo "IP: ${my_default_v4ip}"
    exit 1
  fi
fi

# Assign and Fix varibles

my_name=$(uname -n)
my_name=${my_name//-/_}

if [ "$vpn_connect_to" != "${vpn_connect_to//-/_}" ]; then
  echo "ERROR: - character is not allowed in hostname for vpn_connect_to"
  exit 1
fi

if [ "$reset" != "yes" ] && [ -z "$vpn_connect_to" ]; then
  echo "ERROR: -c <host_to_connect_to> is required"
  exit 1
fi

echo "Options:"
echo "VPN IP: 10.10.1.${vpn_ip_last}"
echo "VPN PORT: ${vpn_port}"
echo "VPN Connect to host: ${vpn_connect_to}"
echo "Public Address: ${my_default_v4ip}"

# Detect and Install
if [ "$(command -v tincd)" == "" ] ; then
  echo "Tinc not found, installing...."
  if [ "$(command -v yum)" != "" ] ; then
    yum install -y tinc
  elif [ "$(command -v apt-get)" != "" ] ; then
    apt-get install -y tinc
  fi
fi

#Create the DIR and key files
mkdir -p /etc/tinc/pvemesh/hosts
chmod 700 /etc/tinc/pvemesh
touch /etc/tinc/pvemesh/rsa_key.pub
touch /etc/tinc/pvemesh/rsa_key.priv
chmod 600 /etc/tinc/pvemesh/rsa_key.priv

if [ "$(grep "BEGIN RSA PUBLIC KEY" /etc/tinc/pvemesh/rsa_key.pub 2> /dev/null)" != "" ] ; then
  if [ "$(grep "BEGIN RSA PRIVATE KEY" /etc/tinc/pvemesh/rsa_key.priv 2> /dev/null)" != "" ] ; then
    echo "Using Previous RSA Keys"
  else
    echo "Generating New RSA Keys"
    if ! tincd -K4096 -c /etc/tinc/pvemesh </dev/null 2>/dev/null; then
      echo "ERROR: RSA key generation failed"
      exit 1
    fi
  fi
else
  echo "Generating New 4096 bit RSA Keys"
  if ! tincd -K4096 -c /etc/tinc/pvemesh </dev/null 2>/dev/null; then
    echo "ERROR: RSA key generation failed"
    exit 1
  fi
fi

# Validate keys were generated
if [ ! -s /etc/tinc/pvemesh/rsa_key.pub ] || ! grep -q "BEGIN RSA PUBLIC KEY" /etc/tinc/pvemesh/rsa_key.pub; then
  echo "ERROR: RSA public key is missing or invalid"
  exit 1
fi
if [ ! -s /etc/tinc/pvemesh/rsa_key.priv ] || ! grep -q "BEGIN RSA PRIVATE KEY" /etc/tinc/pvemesh/rsa_key.priv; then
  echo "ERROR: RSA private key is missing or invalid"
  exit 1
fi

#Generate Configs
cat <<EOF > /etc/tinc/pvemesh/tinc.conf
Name = $my_name
AddressFamily = ipv4
Interface = Tun0
Mode = switch
# tinc 1.0 defaults to blowfish/SHA1. All nodes must match these two lines.
Cipher = aes-256-cbc
Digest = sha256
# compressing before encryption leaks plaintext structure
Compression = 0
# Switch: Unicast, multicast and broadcast packets
ConnectTo = $vpn_connect_to
EOF

cat <<EOF > "/etc/tinc/pvemesh/hosts/$my_name"
Address = ${my_default_v4ip}
Subnet =  10.10.1.${vpn_ip_last}
Port = ${vpn_port}
EOF
cat /etc/tinc/pvemesh/rsa_key.pub >> "/etc/tinc/pvemesh/hosts/${my_name}"

cat <<EOF > /etc/tinc/pvemesh/tinc-up
#!/usr/bin/env bash
set -eu
ip link set "\$INTERFACE" up
ip addr add 10.10.1.${vpn_ip_last}/24 dev "\$INTERFACE"

# Multicast route over the tunnel (iproute2 - net-tools may not be installed)
ip route replace 224.0.0.0/4 dev "\$INTERFACE" || true
EOF

chmod 755 /etc/tinc/pvemesh/tinc-up

cat <<EOF > /etc/tinc/pvemesh/tinc-down
#!/usr/bin/env bash
set -u
ip route del 224.0.0.0/4 dev "\$INTERFACE" 2>/dev/null || true
ip addr del 10.10.1.${vpn_ip_last}/24 dev "\$INTERFACE" 2>/dev/null || true
ip link set "\$INTERFACE" down || true
EOF

chmod 755 /etc/tinc/pvemesh/tinc-down

# Embed the absolute path so the unit does not break if tincd moves
TINCD_BIN="$(command -v tincd || true)"
if [ -z "$TINCD_BIN" ] || [ ! -x "$TINCD_BIN" ]; then
  echo "ERROR: tincd binary not found in PATH after install" >&2
  exit 1
fi

cat <<EOF > /etc/systemd/system/tinc-pvemesh.service
[Unit]
Description=ashimov.com Tinc VPN
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/tinc/pvemesh
ExecStart=${TINCD_BIN} -n pvemesh -D -d2
ExecReload=${TINCD_BIN} -n pvemesh -kHUP
TimeoutStopSec=5
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Enable and start at Boot
systemctl enable tinc-pvemesh.service
systemctl start tinc-pvemesh.service || echo "WARNING: tinc-pvemesh.service failed to start, check logs"

# Add a Tun0 entry to /etc/network/interfaces to allow for ceph suport over the VPN
if [ "$(grep "source /etc/network/interfaces.d/*" /etc/network/interfaces 2> /dev/null)" == "" ] ; then
  echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
  mkdir -p  /etc/network/interfaces.d/
fi
if [ ! -f /etc/network/interfaces.d/tinc-vpn.cfg ]; then
  cat <<EOF > /etc/network/interfaces.d/tinc-vpn.cfg
# tinc vpn
iface Tun0 inet static
  address 10.10.1.${vpn_ip_last}
  netmask 255.255.255.0
  broadcast 10.10.1.255
EOF
fi

#Display the Host config for simple cpy-paste to another node
echo ""
echo "Run the following on the other VPN nodes:"
echo "The following information is stored in /etc/tinc/pvemesh/this_host.info"

echo 'cat <<EOF >> /etc/tinc/pvemesh/hosts/'"${my_name}" > /etc/tinc/pvemesh/this_host.info
cat "/etc/tinc/pvemesh/hosts/${my_name}" >> /etc/tinc/pvemesh/this_host.info
echo "EOF" >> /etc/tinc/pvemesh/this_host.info

echo ""
echo 'cat <<EOF >> /etc/tinc/pvemesh/hosts/'"${my_name}"
cat "/etc/tinc/pvemesh/hosts/${my_name}"
echo "EOF"
echo ""
