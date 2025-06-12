# 🍷 Wine Cellar Monitoring System - Installer

One-click installation script for setting up the Wine Cellar Monitoring System on Raspberry Pi.

## Features

- ✅ Automated installation in ~30-45 minutes
- ✅ Support for both public and private repositories  
- ✅ Automatic system configuration
- ✅ Service setup with auto-start
- ✅ Health monitoring and auto-recovery
- ✅ Security hardening included
- ✅ Post-installation documentation

## Quick Start

```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/My2ndLovE/wl-middleware-installer/main/web-install.sh | bash
Or manually:
bash# Clone the installer
git clone https://github.com/My2ndLovE/wl-middleware-installer.git
cd wl-middleware-installer

# Configure settings
cp config-template.sh installer-config.sh
nano installer-config.sh

# Run installation
./quick-install.sh
Requirements

Raspberry Pi 4 (4GB+ RAM recommended)
Raspberry Pi OS 64-bit (Bullseye or newer)
Internet connection
TP-Link Tapo account with devices

Configuration
Edit installer-config.sh with your settings:
bash# Required
GITHUB_REPO="https://github.com/your-username/tapo-middleware.git"
TAPO_USERNAME="your-email@example.com"
TAPO_PASSWORD="your-password"

# For private repos (choose one)
GITHUB_TOKEN="ghp_your_token_here"
# OR
DEPLOY_KEY_PATH="/home/pi/.ssh/wine_cellar_deploy"
GitHub Authentication
Personal Access Token (Simple)

Go to GitHub Settings > Tokens
Generate new token (classic) with repo scope
Add to installer-config.sh

Deploy Key (Secure)

Run: ./scripts/generate-deploy-key.sh
Follow the interactive guide
Add public key to your GitHub repo

Documentation

Installation Guide
Authentication Guide
Troubleshooting

Support

Issues: Report a bug
Main Project: Wine Cellar Middleware

License
MIT License - See LICENSE file
