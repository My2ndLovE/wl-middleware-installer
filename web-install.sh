#!/bin/bash
# Wine Cellar One-Line Web Installer
# This script is meant to be run with:
# curl -fsSL https://raw.githubusercontent.com/My2ndLovE/wl-middleware-installer/main/web-install.sh | bash

set -e

# Configuration
INSTALLER_REPO="${INSTALLER_REPO:-My2ndLovE/wl-middleware-installer}"
INSTALLER_BRANCH="${INSTALLER_BRANCH:-main}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear

echo -e "${BLUE}"
cat << "BANNER"
 __        ___              ____     _ _           
 \ \      / (_)_ __   ___  / ___|___| | | __ _ _ __ 
  \ \ /\ / /| | '_ \ / _ \| |   / _ \ | |/ _` | '__|
   \ V  V / | | | | |  __/| |__|  __/ | | (_| | |   
    \_/\_/  |_|_| |_|\___| \____\___|_|_|\__,_|_|   
                                                     
     __  __             _ _             _             
    |  \/  | ___  _ __ (_) |_ ___  _ __(_)_ __   __ _ 
    | |\/| |/ _ \| '_ \| | __/ _ \| '__| | '_ \ / _` |
    | |  | | (_) | | | | | || (_) | |  | | | | | (_| |
    |_|  |_|\___/|_| |_|_|\__\___/|_|  |_|_| |_|\__, |
                                                 |___/ 
BANNER
echo -e "${NC}"

echo -e "${GREEN}One-Click Installer for Raspberry Pi${NC}"
echo "====================================="
echo ""

# Check if running on Raspberry Pi (optional check)
if [ -f /proc/cpuinfo ] && grep -q "Raspberry Pi" /proc/cpuinfo; then
    echo -e "${GREEN}✓${NC} Detected Raspberry Pi"
else
    echo -e "${YELLOW}⚠${NC}  Not running on Raspberry Pi (installer will continue anyway)"
fi

# Check for required commands
for cmd in curl tar git; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Installing $cmd...${NC}"
        sudo apt-get update && sudo apt-get install -y $cmd
    fi
done

# Create working directory
INSTALL_DIR="wine-cellar-installer-${INSTALLER_BRANCH}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Previous installation found. Creating backup...${NC}"
    mv "$INSTALL_DIR" "${INSTALL_DIR}-backup-$(date +%s)"
fi

# Download installer
echo ""
echo -e "${BLUE}Downloading installer from GitHub...${NC}"
echo "Repository: $INSTALLER_REPO"
echo "Branch: $INSTALLER_BRANCH"
echo ""

# Download and extract
if curl -sL "https://github.com/${INSTALLER_REPO}/archive/${INSTALLER_BRANCH}.tar.gz" | tar xz; then
    echo -e "${GREEN}✓${NC} Installer downloaded successfully"
else
    echo -e "${RED}✗${NC} Failed to download installer"
    echo "Please check your internet connection and repository settings"
    exit 1
fi

cd "$INSTALL_DIR"

# Make scripts executable
chmod +x *.sh scripts/*.sh 2>/dev/null || true

# Check for existing configuration
if [ -f "../installer-config.sh" ]; then
    echo ""
    echo -e "${GREEN}Found existing configuration file${NC}"
    cp ../installer-config.sh .
else
    # Create configuration from template
    if [ -f "config-template.sh" ]; then
        cp config-template.sh installer-config.sh
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}IMPORTANT: Configuration Required${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Installer ready!${NC}"
echo ""
echo "📁 Location: $(pwd)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "installer-config.sh" ] || grep -q "your-username" installer-config.sh 2>/dev/null; then
    echo "1. Configure your settings:"
    echo "   nano installer-config.sh"
    echo ""
    echo "   Required changes:"
    echo "   - GITHUB_REPO: Your tapo-middleware repository"
    echo "   - TAPO_USERNAME: Your Tapo account email"
    echo "   - TAPO_PASSWORD: Your Tapo account password"
    echo "   - GITHUB_TOKEN: For private repos (see README)"
    echo ""
    echo "2. Run the installer:"
    echo "   ./quick-install.sh"
else
    echo "1. Review your configuration:"
    echo "   nano installer-config.sh"
    echo ""
    echo "2. Run the installer:"
    echo "   ./quick-install.sh"
fi

echo ""
echo "📖 For detailed instructions, see README.md"
echo ""

# Optional: Open editor automatically
read -p "Would you like to edit the configuration now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-nano} installer-config.sh
    echo ""
    echo "Configuration saved. Run './quick-install.sh' when ready!"
fi
