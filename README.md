# 🍷 Wine Cellar Monitoring System - Installer

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![OS](https://img.shields.io/badge/OS-Raspberry%20Pi%20OS-green.svg)](https://www.raspberrypi.com/software/)

**One-click installation script for setting up the Wine Cellar Monitoring System on Raspberry Pi**

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🚀 **Quick Setup** | Automated installation in ~30-45 minutes |
| 🔐 **Flexible Auth** | Support for both public and private repositories |
| ⚙️ **Auto Config** | Automatic system configuration |
| 🔄 **Service Management** | Service setup with auto-start |
| 💪 **Health Monitoring** | Health monitoring and auto-recovery |
| 🛡️ **Security** | Security hardening included |
| 📚 **Documentation** | Post-installation documentation |

## 🚀 Quick Start

### Option 1: One-line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/My2ndLovE/wl-middleware-installer/main/web-install.sh | bash
```

### Option 2: Manual Installation
```bash
# Clone the installer
git clone https://github.com/My2ndLovE/wl-middleware-installer.git
cd wl-middleware-installer

# Configure settings
cp config-template.sh installer-config.sh
nano installer-config.sh

# Run installation
./quick-install.sh
```

## 📋 Requirements

- 🖥️ **Raspberry Pi 4** (4GB+ RAM recommended)
- 💽 **Raspberry Pi OS 64-bit** (Bullseye or newer)
- 🌐 **Internet connection**
- 📱 **TP-Link Tapo account** with devices

## 🌐 Configure Static IP (Recommended)

Setting up a static IP ensures your Wine Cellar Monitoring System is always accessible at the same address.

### Edit the dhcpcd configuration:
```bash
sudo nano /etc/dhcpcd.conf
```

### Add these lines at the end:
```bash
# For Ethernet connection
interface eth0
static ip_address=192.168.0.118/24
static routers=192.168.0.1
static domain_name_servers=192.168.0.1 8.8.8.8

# For WiFi use wlan0 instead:
# interface wlan0
# static ip_address=192.168.0.118/24
# static routers=192.168.0.1
# static domain_name_servers=192.168.0.1 8.8.8.8
```

### Reboot to apply changes:
```bash
sudo reboot
```

> **💡 Note:** Adjust the IP address (`192.168.0.118`) and gateway (`192.168.0.1`) according to your network configuration.

## ⚙️ Configuration

Edit `installer-config.sh` with your settings:

```bash
# Required settings
GITHUB_REPO="https://github.com/your-username/tapo-middleware.git"
TAPO_USERNAME="your-email@example.com"
TAPO_PASSWORD="your-password"

# For private repos (choose one)
GITHUB_TOKEN="ghp_your_token_here"
# OR
DEPLOY_KEY_PATH="/home/pi/.ssh/wine_cellar_deploy"
```

## 🔐 GitHub Authentication

### 🎫 Personal Access Token (Simple)

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Generate new token (classic) with `repo` scope
3. Add to `installer-config.sh`

### 🔑 Deploy Key (Secure)

1. Run: `./scripts/generate-deploy-key.sh`
2. Follow the interactive guide
3. Add public key to your GitHub repo

## 📖 Documentation

- 📋 [Installation Guide](docs/installation.md)
- 🔐 [Authentication Guide](docs/authentication.md)
- 🔧 [Troubleshooting](docs/troubleshooting.md)

## 🆘 Support

- 🐛 **Issues**: [Report a bug](https://github.com/My2ndLovE/wl-middleware-installer/issues)
- 🍷 **Main Project**: [Wine Cellar Middleware](https://github.com/My2ndLovE/tapo-middleware)

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

<div align="center">
Made with ❤️ for wine enthusiasts
</div>
