#!/usr/bin/env bash
################################################################################
# This is property of ashimov.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Berik Ashimov :: berik@ashimov.com
################################################################################
#
# Script updates can be found at: https://github.com/ashimov/proxmox-optimizer
#
# Debian 12 (Bookworm) to Proxmox VE 8 conversion script
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Assumptions: Debian 12 installed with a valid FQDN hostname set
#
# Tested on KVM, VirtualBox and Dedicated Server
#
# Will automatically detect cloud-init and disable.
# Will automatically generate a correct /etc/hosts
#
# Note: will automatically run the install-post.sh script
#
# Usage:
# curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian12-2-proxmox8.sh && chmod +x debian12-2-proxmox8.sh
# ./debian12-2-proxmox8.sh
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"
sh -c "echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale"

# Create lock dir for aptitude
if [ ! -d "/run/lock" ] ; then
  mkdir /run/lock
  chmod a+rwxt /run/lock
fi

# Check Debian version
if [ ! -f /etc/os-release ]; then
  echo "ERROR: Cannot detect OS version"
  exit 1
fi

source /etc/os-release
if [ "$VERSION_CODENAME" != "bookworm" ]; then
  echo "ERROR: This script is for Debian 12 (Bookworm) only"
  echo "Detected: $PRETTY_NAME"
  exit 1
fi

echo "Deinstalling any linux firmware packages"
firmware="$(dpkg -l | grep -i 'firmware-')"
if [ -n "$firmware" ]; then
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge firmware-bnx2x firmware-realtek firmware-linux firmware-linux-free firmware-linux-nonfree
else
  echo "No firmware packages loaded"
fi

echo "Deinstalling the Debian standard kernel packages"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge linux-image-amd64

echo "Removing conflicting packages"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge os-prober
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoremove
apt-get clean all

echo "Auto detecting existing network settings"
default_interface="$(ip route | awk '/default/ { print $5 }' | grep -v "vmbr")"
if [ "$default_interface" == "" ]; then
  # Filter the interfaces to get the default interface and which is not down and not a virtual bridge
  default_interface="$(ip link | sed -e '/state DOWN / { N; d; }' | sed -e '/veth[0-9].*:/ { N; d; }' | sed -e '/vmbr[0-9].*:/ { N; d; }' | sed -e '/tap[0-9].*:/ { N; d; }' | sed -e '/lo:/ { N; d; }' | head -n 1 | cut -d':' -f 2 | xargs)"
fi
if [ "$default_interface" == "" ]; then
  echo "ERROR: Could not detect default interface"
  exit 1
fi
default_v4="$(ip -4 addr show dev "$default_interface" | awk '/inet/ { print $2 }' )"
default_v4ip=${default_v4%/*}
if [ "$default_v4ip" == "" ] ; then
  echo "ERROR: Could not detect default IPv4 address"
  echo "IP: ${default_v4ip}"
  exit 1
fi

echo "Configure /etc/hosts"
if [ -f /etc/cloud/cloud.cfg ] ; then
  echo 'manage_etc_hosts: False' | tee --append /etc/cloud/cloud.cfg
  sed -i "s/^ - update_etc_hosts/# - update_etc_hosts/" /etc/cloud/cloud.cfg
fi
cat <<EOF > /etc/hosts
127.0.0.1 localhost.localdomain localhost
${default_v4ip} $(hostname -f) $(hostname -s) pvelocalhost
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

echo "Add Proxmox VE 8 repo to APT sources"
mkdir -p /etc/apt/keyrings
wget -q "https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg" -O /etc/apt/keyrings/proxmox-release-bookworm.gpg
cat <<EOF > /etc/apt/sources.list.d/pve-no-subscription.list
# PVE packages provided by proxmox.com
deb [arch=amd64 signed-by=/etc/apt/keyrings/proxmox-release-bookworm.gpg] https://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
apt-get update > /dev/null

echo "Upgrading system"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' full-upgrade

echo "Installing postfix"
cat <<EOF | debconf-set-selections
postfix postfix/mailname           string $(cat /etc/hostname)
postfix postfix/destinations       string $(cat /etc/hostname), proxmox, localhost.localdomain, localhost
postfix postfix/chattr             boolean false
postfix postfix/mailbox_limit      string 0
postfix postfix/main_mailer_type   select Local only
postfix postfix/mynetworks         string 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
postfix postfix/protocols          select all
postfix postfix/recipient_delim    string +
postfix postfix/rfc1035_violation  boolean false
EOF
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install -y postfix

echo "Installing open-iscsi"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install -y open-iscsi

echo "Installing proxmox-ve"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install -y proxmox-ve

echo "Remove legacy kernel"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' remove linux-image-amd64 'linux-image-6.1*'

echo "Force grub to update"
update-grub

echo "Remove os-prober"
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' remove os-prober

echo "Remove enterprise repo if exists"
rm -f /etc/apt/sources.list.d/pve-enterprise.list

echo "Done installing Proxmox VE 8"

echo "Creating admin user"
pveum groupadd admin -comment "System Administrators" 2>/dev/null || true
pveum aclmod / -group admin -role Administrator
pveum useradd admin@pve -comment "Admin" 2>/dev/null || true
pveum usermod admin@pve -group admin

echo "Fetching postinstall script"
wget https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/install-post.sh -c -O install-post.sh && chmod +x install-post.sh
if grep -q '#!/usr/bin/env bash' "install-post.sh"; then
  bash install-post.sh
fi

echo "Setting admin user password"
pveum passwd admin@pve
