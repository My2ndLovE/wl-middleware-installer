#!/bin/bash
# Wine Cellar Monitoring System - Uninstaller
# This script safely removes the Wine Cellar installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
PI_USERNAME="${PI_USERNAME:-wladmin}"
BACKUP_DATA=true

echo -e "${RED}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Wine Cellar Monitoring System - Uninstaller          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  WARNING: This will remove the Wine Cellar Monitoring System${NC}"
echo ""

# Check what will be removed
echo "The following will be removed:"
echo "- Systemd service (tapo-middleware.service)"
echo "- Application directory (/home/$PI_USERNAME/tapo-middleware)"
echo "- Nginx configuration"
echo "- Cron jobs"
echo "- Log files"
echo ""

if [ "$BACKUP_DATA" = true ]; then
    echo -e "${GREEN}✓ Device data and settings will be backed up${NC}"
else
    echo -e "${RED}✗ Device data and settings will be deleted${NC}"
fi

echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Starting uninstallation...${NC}"

# Stop and disable service
echo "Stopping service..."
sudo systemctl stop tapo-middleware.service 2>/dev/null || true
sudo systemctl disable tapo-middleware.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/tapo-middleware.service
sudo systemctl daemon-reload

# Remove from crontab
echo "Removing cron jobs..."
crontab -l 2>/dev/null | grep -v "tapo-middleware" | grep -v "daily-maintenance" | crontab - || true

# Backup data if requested
if [ "$BACKUP_DATA" = true ] && [ -d "/home/$PI_USERNAME/tapo-middleware/data" ]; then
    backup_dir="/home/$PI_USERNAME/wine-cellar-backup-$(date +%Y%m%d-%H%M%S)"
    echo "Creating backup at $backup_dir..."
    mkdir -p "$backup_dir"
    cp -r "/home/$PI_USERNAME/tapo-middleware/data" "$backup_dir/" 2>/dev/null || true
    cp "/home/$PI_USERNAME/tapo-middleware/.env" "$backup_dir/" 2>/dev/null || true
    echo -e "${GREEN}✅ Backup created at: $backup_dir${NC}"
fi

# Remove nginx configuration
echo "Removing web server configuration..."
sudo rm -f /etc/nginx/sites-enabled/wine-cellar
sudo rm -f /etc/nginx/sites-available/wine-cellar
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo systemctl reload nginx 2>/dev/null || true

# Remove application directory
echo "Removing application files..."
rm -rf "/home/$PI_USERNAME/tapo-middleware"

# Remove maintenance scripts
rm -f "/home/$PI_USERNAME/daily-maintenance.sh"
rm -f "/home/$PI_USERNAME/view-maintenance-history.sh"
rm -f "/home/$PI_USERNAME/WINE_CELLAR_INFO.txt"
rm -f "/home/$PI_USERNAME/QUICK_REFERENCE.txt"
rm -f "/home/$PI_USERNAME/SYSTEM_INFO.txt"

# Remove log directory (optional)
read -p "Remove log files? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "/home/$PI_USERNAME/tapo-middleware/logs"
fi

# Remove firewall rules
echo "Removing firewall rules..."
sudo ufw delete allow from 192.168.0.0/24 to any port 3000 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Uninstallation complete!${NC}"
echo ""

if [ "$BACKUP_DATA" = true ]; then
    echo "Your data has been backed up to: $backup_dir"
    echo "You can restore it later if needed."
fi

echo ""
echo "The following were removed:"
echo "- Wine Cellar Monitoring application"
echo "- System service and automation"
echo "- Web server configuration"
echo ""
echo "The following were NOT removed:"
echo "- System packages (python3, nginx, etc.)"
echo "- Firewall (still enabled)"
echo "- Your backup data (if created)"
echo ""
echo "Thank you for using Wine Cellar Monitoring System!"
