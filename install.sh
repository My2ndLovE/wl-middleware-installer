# ==============================================================================
# CONFIGURATION SECTION - THESE SHOULD BE SET BY installer-config.sh
# ==============================================================================

# Git Repository Configuration
GITHUB_REPO="${GITHUB_REPO:-}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
DEPLOY_KEY_PATH="${DEPLOY_KEY_PATH:-}"

# Tapo Account Credentials
TAPO_USERNAME="${TAPO_USERNAME:-}"
TAPO_PASSWORD="${TAPO_PASSWORD:-}"

# System Configuration
PI_USERNAME="${PI_USERNAME:-wladmin}"
CLIENT_ID="${CLIENT_ID:-wine-cellar-001}"
TIMEZONE="${TIMEZONE:-Asia/Kuala_Lumpur}"
API_SECRET="${API_SECRET:-wine-cellar-secret-key-change-this-$(date +%s)}"

# Network Configuration
ALLOWED_NETWORK="${ALLOWED_NETWORK:-192.168.0.0/24}"
ALERT_EMAIL="${ALERT_EMAIL:-}"

# ==============================================================================
# COLOR CODES FOR OUTPUT
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_header() {
    echo -e "\n${BLUE}==============================================================================\n$1\n==============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_warning "This script is designed for Raspberry Pi but will continue anyway..."
        read -p "Continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to validate required variables
validate_config() {
    local errors=0
    
    if [[ "$GITHUB_REPO" == *"your-username"* ]]; then
        print_error "Please update GITHUB_REPO with your actual repository URL"
        errors=$((errors + 1))
    fi
    
    if [[ "$TAPO_USERNAME" == *"@example.com"* ]]; then
        print_error "Please update TAPO_USERNAME with your actual Tapo account email"
        errors=$((errors + 1))
    fi
    
    if [[ "$TAPO_PASSWORD" == "your_tapo_password" ]]; then
        print_error "Please update TAPO_PASSWORD with your actual Tapo account password"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "Please fix the configuration errors above before running the installer"
        exit 1
    fi
}

# Function to setup Git authentication
setup_git_auth() {
    if [ -n "$GITHUB_TOKEN" ]; then
        print_info "Setting up GitHub authentication with Personal Access Token..."
        
        # Extract username and repo from URL
        if [[ "$GITHUB_REPO" =~ github\.com[:/]([^/]+)/(.+)\.git$ ]]; then
            GIT_USERNAME="${BASH_REMATCH[1]}"
            GIT_REPONAME="${BASH_REMATCH[2]}"
            
            # Create authenticated URL
            AUTHENTICATED_REPO="https://${GITHUB_TOKEN}@github.com/${GIT_USERNAME}/${GIT_REPONAME}.git"
        else
            print_error "Could not parse GitHub repository URL"
            exit 1
        fi
    elif [ -n "$DEPLOY_KEY_PATH" ] && [ -f "$DEPLOY_KEY_PATH" ]; then
        print_info "Setting up GitHub authentication with Deploy Key..."
        
        # Setup SSH config for deploy key
        mkdir -p ~/.ssh
        cp "$DEPLOY_KEY_PATH" ~/.ssh/deploy_key
        chmod 600 ~/.ssh/deploy_key
        
        # Configure SSH to use deploy key for GitHub
        cat >> ~/.ssh/config << SSHEOF

Host github-deploy
    Hostname github.com
    User git
    IdentityFile ~/.ssh/deploy_key
    IdentitiesOnly yes
    StrictHostKeyChecking no
SSHEOF
        
        # Convert HTTPS URL to SSH URL with custom host
        if [[ "$GITHUB_REPO" =~ github\.com[:/]([^/]+)/(.+)\.git$ ]]; then
            GIT_USERNAME="${BASH_REMATCH[1]}"
            GIT_REPONAME="${BASH_REMATCH[2]}"
            AUTHENTICATED_REPO="git@github-deploy:${GIT_USERNAME}/${GIT_REPONAME}.git"
        else
            print_error "Could not parse GitHub repository URL"
            exit 1
        fi
    else
        # Public repository - no authentication needed
        AUTHENTICATED_REPO="$GITHUB_REPO"
        print_info "Using public repository (no authentication required)"
    fi
}

# Function to create backup of existing installation
backup_existing() {
    if [ -d "/home/$PI_USERNAME/tapo-middleware" ]; then
        print_warning "Existing installation found. Creating backup..."
        backup_dir="/home/$PI_USERNAME/tapo-middleware-backup-$(date +%Y%m%d-%H%M%S)"
        sudo mv "/home/$PI_USERNAME/tapo-middleware" "$backup_dir"
        print_success "Backup created at: $backup_dir"
    fi
}

# ==============================================================================
# MAIN INSTALLATION SCRIPT
# ==============================================================================

print_header "Wine Cellar Monitoring System - One-Click Installer"
echo "This script will automatically install and configure the complete system."
echo "Installation time: approximately 30-45 minutes"
echo ""

# Pre-flight checks
print_info "Running pre-flight checks..."
check_raspberry_pi
validate_config
setup_git_auth

# Get system information
PI_IP=$(hostname -I | awk '{print $1}')
print_info "Detected IP address: $PI_IP"

# Confirm installation
echo ""
read -p "Ready to install Wine Cellar Monitoring System? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
fi

# Start installation timer
START_TIME=$(date +%s)

# ==============================================================================
# PHASE 1: SYSTEM UPDATE AND BASIC SETUP
# ==============================================================================

print_header "Phase 1: System Update and Basic Setup"

print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_info "Installing required packages..."
sudo apt install -y \
    git python3-pip python3-venv python3-dev \
    curl wget htop nano ufw net-tools \
    build-essential libssl-dev libffi-dev \
    nginx jq bc

print_info "Configuring timezone..."
sudo timedatectl set-timezone "$TIMEZONE"

print_info "Setting hostname..."
sudo hostnamectl set-hostname wine-cellar-monitor

print_success "System update complete"

# ==============================================================================
# PHASE 2: SECURITY CONFIGURATION
# ==============================================================================

print_header "Phase 2: Security Configuration"

print_info "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp  # For nginx
sudo ufw allow from "$ALLOWED_NETWORK" to any port 3000 comment "Wine Cellar API"
sudo ufw reload

print_success "Security configuration complete"

# ==============================================================================
# PHASE 3: APPLICATION INSTALLATION
# ==============================================================================

print_header "Phase 3: Application Installation"

# Ensure we're in the right directory
cd "/home/$PI_USERNAME"

# Backup existing installation if found
backup_existing

print_info "Cloning repository..."
git clone "$AUTHENTICATED_REPO" tapo-middleware

# Clean up token from URL in git config for security
cd tapo-middleware
if [ -n "$GITHUB_TOKEN" ]; then
    git remote set-url origin "$GITHUB_REPO"
fi
cd ..

cd tapo-middleware

# Checkout specific branch if specified
if [ -n "$GITHUB_BRANCH" ] && [ "$GITHUB_BRANCH" != "main" ]; then
    print_info "Switching to branch: $GITHUB_BRANCH"
    git checkout "$GITHUB_BRANCH"
fi

# Set proper ownership
sudo chown -R "$PI_USERNAME:$PI_USERNAME" "/home/$PI_USERNAME/tapo-middleware"

print_info "Creating Python virtual environment..."
python3 -m venv venv

print_info "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

print_success "Application installation complete"

# ==============================================================================
# PHASE 4: APPLICATION CONFIGURATION
# ==============================================================================

print_header "Phase 4: Application Configuration"

print_info "Creating configuration files..."

# Create .env file
cat > .env << ENVEOF
# Tapo Account Credentials
TAPO_USERNAME=$TAPO_USERNAME
TAPO_PASSWORD=$TAPO_PASSWORD

# API Configuration
API_SECRET=$API_SECRET
API_HOST=0.0.0.0
API_PORT=3000
LOG_LEVEL=WARNING

# Wine Cellar Configuration
CLIENT_ID=$CLIENT_ID
ENVEOF

# Secure the .env file
chmod 600 .env

# Create data directory and settings
mkdir -p data logs

# Create default settings.json
cat > data/settings.json << JSONEOF
{
  "auto_ip_discovery": true,
  "monitor_interval": 30,
  "ui_refresh_interval": 5,
  "wine_cellar_mac": null,
  "hub_mac": null,
  "remote_bridge_url": null,
  "client_id": "$CLIENT_ID",
  "minimal_logging": true
}
JSONEOF

# Make scripts executable
chmod +x scripts/*.sh

print_success "Configuration complete"

# ==============================================================================
# PHASE 5: SYSTEMD SERVICE SETUP
# ==============================================================================

print_header "Phase 5: Service Configuration"

print_info "Creating systemd service..."

sudo tee /etc/systemd/system/tapo-middleware.service > /dev/null << SERVICEEOF
[Unit]
Description=Tapo Middleware Wine Cellar Monitoring
After=network-online.target time-sync.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=forking
User=$PI_USERNAME
Group=$PI_USERNAME
WorkingDirectory=/home/$PI_USERNAME/tapo-middleware
Environment="PATH=/home/$PI_USERNAME/tapo-middleware/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/$PI_USERNAME/tapo-middleware/scripts/startup.sh start
ExecStop=/home/$PI_USERNAME/tapo-middleware/scripts/startup.sh stop
ExecReload=/home/$PI_USERNAME/tapo-middleware/scripts/startup.sh restart
PIDFile=/tmp/tapo-api.pid
Restart=always
RestartSec=15
TimeoutStartSec=120

# Resource limits for Pi
MemoryMax=512M
TasksMax=50

# Security
NoNewPrivileges=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
SERVICEEOF

print_info "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable tapo-middleware.service
sudo systemctl start tapo-middleware.service

# Wait for service to start
sleep 10

# Check if service started successfully
if sudo systemctl is-active --quiet tapo-middleware.service; then
    print_success "Service started successfully"
else
    print_error "Service failed to start. Checking logs..."
    sudo journalctl -u tapo-middleware.service --no-pager -n 20
    exit 1
fi

# ==============================================================================
# PHASE 6: NGINX REVERSE PROXY SETUP
# ==============================================================================

print_header "Phase 6: Web Server Configuration"

print_info "Configuring Nginx reverse proxy..."

# Create nginx configuration
sudo tee /etc/nginx/sites-available/wine-cellar > /dev/null << NGINXEOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Main application
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # API endpoints
    location /api {
        proxy_pass http://localhost:3000/api;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINXEOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/wine-cellar /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx

print_success "Web server configured"

# ==============================================================================
# PHASE 7: MONITORING AND MAINTENANCE SETUP
# ==============================================================================

print_header "Phase 7: Monitoring and Maintenance Setup"

print_info "Creating health check script..."

# Create the hourly health check script
cat > scripts/hourly-health.sh << 'HEALTHEOF'
#!/bin/bash
HEALTH_URL="http://localhost:3000/health"
LOG_FILE="/home/wladmin/tapo-middleware/logs/health.log"

if curl -s --max-time 5 "$HEALTH_URL" | grep -q "healthy"; then
    exit 0
else
    echo "[$(date)] Wine cellar monitoring failed health check - restarting" >> "$LOG_FILE"
    sudo systemctl restart tapo-middleware.service
    echo "[$(date)] Service restart completed" >> "$LOG_FILE"
fi
HEALTHEOF

chmod +x scripts/hourly-health.sh

# Update the path in the script
sed -i "s/wladmin/$PI_USERNAME/g" scripts/hourly-health.sh

print_info "Creating maintenance script..."

# Create comprehensive maintenance script
cat > /home/$PI_USERNAME/daily-maintenance.sh << 'MAINTENANCE_EOF'
#!/bin/bash
# Daily maintenance script with logging

LOG_FILE="/home/wladmin/tapo-middleware/logs/daily-maintenance.log"
HEALTH_URL="http://localhost:3000/health"
MAX_LOG_SIZE=10485760  # 10MB

mkdir -p "$(dirname "$LOG_FILE")"

if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
fi

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

SILENT=false
if [ "$1" = "--silent" ]; then
    SILENT=true
fi

if [ "$SILENT" = false ]; then
    log_message "=== DAILY WINE CELLAR SYSTEM CHECK ==="
fi

# Service check
SERVICE_STATUS=$(sudo systemctl is-active tapo-middleware.service 2>/dev/null)
log_message "Service Status: $SERVICE_STATUS"

# API health check
API_HEALTH=$(curl -s --max-time 10 "$HEALTH_URL" 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
log_message "API Health: ${API_HEALTH:-FAILED}"

# Device status
DEVICE_INFO=$(curl -s --max-time 10 "http://localhost:3000/api/monitor/status" 2>/dev/null)
if [ -n "$DEVICE_INFO" ]; then
    ONLINE=$(echo "$DEVICE_INFO" | jq -r '.online // 0')
    TOTAL=$(echo "$DEVICE_INFO" | jq -r '.total // 0')
    log_message "Devices: $ONLINE/$TOTAL online"
fi

# System resources
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}')
CPU_TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d"'" -f1 || echo "N/A")

log_message "Memory: $MEMORY_USAGE, Disk: $DISK_USAGE, CPU Temp: ${CPU_TEMP}°C"

# Auto-recovery if needed
if [ "$SERVICE_STATUS" != "active" ] || [ "$API_HEALTH" != "healthy" ]; then
    log_message "🔧 AUTO-RECOVERY: Restarting service..."
    sudo systemctl restart tapo-middleware.service
fi

if [ "$SILENT" = false ]; then
    log_message "=== CHECK COMPLETE ==="
fi
MAINTENANCE_EOF

# Update username in maintenance script
sed -i "s/wladmin/$PI_USERNAME/g" /home/$PI_USERNAME/daily-maintenance.sh
chmod +x /home/$PI_USERNAME/daily-maintenance.sh

print_info "Setting up cron jobs..."

# Add cron jobs
(
    crontab -l 2>/dev/null || true
    echo "0 * * * * /home/$PI_USERNAME/tapo-middleware/scripts/hourly-health.sh"
    echo "0 8 * * * /home/$PI_USERNAME/daily-maintenance.sh --silent"
) | crontab -

print_success "Monitoring setup complete"

# ==============================================================================
# PHASE 8: INITIAL DEVICE DISCOVERY
# ==============================================================================

print_header "Phase 8: Initial Device Discovery"

print_info "Waiting for API to stabilize..."
sleep 5

# Check if API is responding
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    print_success "API is healthy"
    
    print_info "Starting device discovery..."
    discovery_response=$(curl -s -X POST http://localhost:3000/api/discovery/scan)
    
    if echo "$discovery_response" | grep -q "started"; then
        print_success "Device discovery started"
        print_info "Discovery will run in background for about 60 seconds"
    else
        print_warning "Could not start device discovery. You can do this manually later."
    fi
else
    print_warning "API not ready. You'll need to run device discovery manually."
fi

# ==============================================================================
# PHASE 9: CREATE DOCUMENTATION
# ==============================================================================

print_header "Phase 9: Creating Documentation"

# Create system info file
cat > /home/$PI_USERNAME/WINE_CELLAR_INFO.txt << INFOEOF
=== Wine Cellar Monitoring System ===
Installation Date: $(date)
System Version: 2.0 (v2-simplification)

=== Access Information ===
Pi IP Address: $PI_IP
Public Monitor: http://$PI_IP/
Admin Interface: http://$PI_IP/static/admin/
API Documentation: http://$PI_IP:3000/docs

=== Service Management ===
Check Status: sudo systemctl status tapo-middleware
Restart Service: sudo systemctl restart tapo-middleware
View Logs: sudo journalctl -u tapo-middleware -f

=== Quick Commands ===
Run Maintenance Check: /home/$PI_USERNAME/daily-maintenance.sh
Device Discovery: curl -X POST http://localhost:3000/api/discovery/scan
Test Wine Cellar Light: curl -X POST http://localhost:3000/api/cellar/light -H "Content-Type: application/json" -d '{"state": "toggle"}'

=== Configuration Files ===
Settings: /home/$PI_USERNAME/tapo-middleware/data/settings.json
Environment: /home/$PI_USERNAME/tapo-middleware/.env
Service: /etc/systemd/system/tapo-middleware.service

=== Support ===
Repository: $GITHUB_REPO
Client ID: $CLIENT_ID
INFOEOF

# Create quick reference card
cat > /home/$PI_USERNAME/QUICK_REFERENCE.txt << 'QUICKEOF'
🍷 WINE CELLAR MONITOR - QUICK REFERENCE

📱 ACCESS URLS:
   Public:  http://YOUR_PI_IP/
   Admin:   http://YOUR_PI_IP/static/admin/

🔧 COMMON TASKS:
   Check Status:    sudo systemctl status tapo-middleware
   Restart:         sudo systemctl restart tapo-middleware
   View Logs:       sudo journalctl -u tapo-middleware -f
   Test Health:     curl http://localhost:3000/health

🚨 TROUBLESHOOTING:
   1. Service won't start:
      - Check logs: sudo journalctl -u tapo-middleware -n 50
      - Verify credentials in .env file
   
   2. Can't find devices:
      - Run discovery: curl -X POST http://localhost:3000/api/discovery/scan
      - Check network: devices must be on same network
   
   3. Web interface not loading:
      - Check nginx: sudo systemctl status nginx
      - Check API: curl http://localhost:3000/health

📞 EMERGENCY:
   If auto-recovery fails, run manually:
   cd /home/wladmin/tapo-middleware
   ./scripts/startup.sh restart
QUICKEOF

sed -i "s/wladmin/$PI_USERNAME/g" /home/$PI_USERNAME/QUICK_REFERENCE.txt
sed -i "s/YOUR_PI_IP/$PI_IP/g" /home/$PI_USERNAME/QUICK_REFERENCE.txt

print_success "Documentation created"

# ==============================================================================
# INSTALLATION COMPLETE
# ==============================================================================

END_TIME=$(date +%s)
INSTALL_TIME=$((END_TIME - START_TIME))
INSTALL_MINUTES=$((INSTALL_TIME / 60))

print_header "Installation Complete! 🎉"

echo ""
echo "Installation Summary:"
echo "===================="
print_success "✅ System updated and configured"
print_success "✅ Application installed from: $GITHUB_REPO"
print_success "✅ Service running as: tapo-middleware.service"
print_success "✅ Web server configured on port 80"
print_success "✅ Monitoring and auto-recovery enabled"
print_success "✅ Documentation created"
echo ""
echo "Installation time: $INSTALL_MINUTES minutes"
echo ""
echo "🍷 Access your Wine Cellar Monitor:"
echo "=================================="
echo "📱 Public Monitor:  http://$PI_IP/"
echo "⚙️  Admin Panel:    http://$PI_IP/static/admin/"
echo "📊 API Docs:        http://$PI_IP:3000/docs"
echo ""
echo "📋 Next Steps:"
echo "============="
echo "1. Access the admin panel and run device discovery"
echo "2. Identify your hub and wine cellar light"
echo "3. Configure settings as needed"
echo "4. Test the system with a power cycle"
echo ""
echo "📖 Documentation saved to:"
echo "   /home/$PI_USERNAME/WINE_CELLAR_INFO.txt"
echo "   /home/$PI_USERNAME/QUICK_REFERENCE.txt"
echo ""

# Final health check
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    print_success "🟢 System is healthy and ready!"
else
    print_warning "⚠️  System may still be starting up. Check in a few minutes."
fi

echo ""
echo "Thank you for using Wine Cellar Monitor! 🍷"
