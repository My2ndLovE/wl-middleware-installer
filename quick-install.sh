#!/bin/bash
# Wine Cellar Quick Installer
# This wrapper makes installation even simpler

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         🍷 Wine Cellar Monitoring System Installer 🍷         ║"
echo "║                    One-Click Installation                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if configuration exists
if [ ! -f "installer-config.sh" ]; then
    echo -e "${RED}❌ Configuration file not found!${NC}"
    echo ""
    echo "Please follow these steps:"
    echo "1. Copy installer-config-template.sh to installer-config.sh"
    echo "   cp installer-config-template.sh installer-config.sh"
    echo ""
    echo "2. Edit installer-config.sh with your settings:"
    echo "   nano installer-config.sh"
    echo ""
    echo "3. Run this installer again"
    echo ""
    exit 1
fi

# Load configuration
echo -e "${BLUE}Loading configuration...${NC}"
source installer-config.sh

# Validate critical settings
if [[ "$GITHUB_REPO" == *"your-username"* ]]; then
    echo -e "${RED}❌ Please update GITHUB_REPO in installer-config.sh${NC}"
    exit 1
fi

if [[ "$TAPO_USERNAME" == *"@example.com"* ]]; then
    echo -e "${RED}❌ Please update TAPO_USERNAME in installer-config.sh${NC}"
    exit 1
fi

# Show configuration summary
echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repository:    $GITHUB_REPO"
echo "Branch:        $GITHUB_BRANCH"
echo "Client ID:     $CLIENT_ID"
echo "Timezone:      $TIMEZONE"
echo "Network:       $ALLOWED_NETWORK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Download the main installer if not present
if [ ! -f "wine-cellar-installer.sh" ]; then
    echo -e "${BLUE}Downloading main installer...${NC}"
    curl -fsSL https://raw.githubusercontent.com/My2ndLovE/wl-middleware-installer/main/install.sh -o wine-cellar-installer.sh
    chmod +x wine-cellar-installer.sh
fi

# Confirm installation
read -p "Ready to install? This will take about 30-45 minutes. (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Run the main installer
echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Export all variables for the main installer
export GITHUB_REPO GITHUB_BRANCH TAPO_USERNAME TAPO_PASSWORD
export PI_USERNAME CLIENT_ID TIMEZONE ALLOWED_NETWORK
export ALERT_EMAIL API_PORT LOG_LEVEL MONITOR_INTERVAL UI_REFRESH_INTERVAL
export GITHUB_TOKEN DEPLOY_KEY_PATH

# Copy main installer to wine-cellar-installer.sh if it's named install.sh
if [ -f "install.sh" ] && [ ! -f "wine-cellar-installer.sh" ]; then
    cp install.sh wine-cellar-installer.sh
    chmod +x wine-cellar-installer.sh
fi

# Execute main installer
./wine-cellar-installer.sh

# Installation complete
echo ""
echo -e "${GREEN}✨ Quick installation completed! ✨${NC}"
