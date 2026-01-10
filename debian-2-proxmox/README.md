# 🔄 Debian to Proxmox Conversion Scripts

<div align="center">

[![Debian](https://img.shields.io/badge/Debian-13%20|%2012%20|%2011-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Proxmox](https://img.shields.io/badge/Proxmox-9.x%20|%208.x%20|%207.x-E57000)](https://www.proxmox.com/)

*Convert clean Debian installations to Proxmox VE*

</div>

---

## 📋 Available Scripts

| Script | Debian | Proxmox | Status |
|--------|--------|---------|--------|
| `debian13-2-proxmox9.sh` | 13 (Trixie) | VE 9.x | ✅ **Recommended** |
| `debian12-2-proxmox8.sh` | 12 (Bookworm) | VE 8.x | ✅ Supported |
| `debian11-2-proxmox7.sh` | 11 (Bullseye) | VE 7.x | ⚠️ Deprecated |

---

## ⚙️ Prerequisites

- Clean Debian installation
- Valid **FQDN hostname** set
- Root access
- Internet connectivity

### Tested Environments
- ✅ KVM Virtual Machines
- ✅ VirtualBox
- ✅ Dedicated Servers

---

## 🚀 Installation

### Debian 13 → Proxmox VE 9 ⭐ Recommended

```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian13-2-proxmox9.sh
chmod +x debian13-2-proxmox9.sh
./debian13-2-proxmox9.sh
```

### Debian 12 → Proxmox VE 8

```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian12-2-proxmox8.sh
chmod +x debian12-2-proxmox8.sh
./debian12-2-proxmox8.sh
```

### Debian 11 → Proxmox VE 7 ⚠️

> **Warning:** Proxmox 7 is end-of-life. Upgrade to Debian 12 or 13 for supported versions.

```bash
curl -O https://raw.githubusercontent.com/ashimov/proxmox-optimizer/master/debian-2-proxmox/debian11-2-proxmox7.sh
chmod +x debian11-2-proxmox7.sh
./debian11-2-proxmox7.sh
```

---

## ✨ Features

All conversion scripts automatically:

- ✅ Detect and disable cloud-init
- ✅ Generate correct `/etc/hosts`
- ✅ Remove conflicting packages (os-prober, firmware)
- ✅ Add Proxmox APT repositories
- ✅ Install Proxmox VE packages
- ✅ Configure postfix (local only)
- ✅ Create admin user with Administrator role
- ✅ Run post-installation optimizer (`install-post.sh`)

---

## 📝 Post-Installation

After script completion:

1. **Reboot** the system
2. Access web interface at `https://your-ip:8006`
3. Login options:
   - `root@pam` (Linux PAM)
   - `admin@pve` (Proxmox user, password set during install)

---

## 🔧 What Gets Installed

| Component | Description |
|-----------|-------------|
| `proxmox-ve` | Main Proxmox VE package |
| `postfix` | Mail transport agent (local only) |
| `open-iscsi` | iSCSI initiator |
| PVE Kernel | Proxmox optimized kernel |

---

## ⚠️ Important Notes

- **Backup data** before running conversion
- Ensure hostname is a valid FQDN (e.g., `server.domain.com`)
- Script removes standard Debian kernel
- Enterprise repository is disabled automatically
- Post-install script runs automatically at the end

---

<div align="center">

*Part of [Proxmox Optimizer](https://github.com/ashimov/proxmox-optimizer)*

</div>
