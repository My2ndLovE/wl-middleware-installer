#!/bin/bash
# Wine Cellar Monitoring System - Configuration File
# 
# Instructions:
# 1. Copy this file to 'installer-config.sh'
# 2. Edit the values below with your actual information
# 3. Run: ./wine-cellar-installer.sh
#
# The installer will source this configuration file automatically

# ==============================================================================
# REQUIRED CONFIGURATION - YOU MUST UPDATE THESE
# ==============================================================================

# GitHub Repository containing the tapo-middleware code
# Replace with your forked repository URL
export GITHUB_REPO="https://github.com/your-username/tapo-middleware.git"

# Git branch to use (usually "main" or "v2-simplification")
export GITHUB_BRANCH="main"

# ==============================================================================
# GITHUB AUTHENTICATION (Required for Private Repositories)
# ==============================================================================
# Choose ONE of the following methods:

# Method 1: Personal Access Token (Recommended)
# 1. Go to https://github.com/settings/tokens
# 2. Click "Generate new token" -> "Generate new token (classic)"
# 3. Give it a name like "wine-cellar-pi"
# 4. Select scopes: ✅ repo (Full control of private repositories)
# 5. Generate token and paste it below
export GITHUB_TOKEN=""

# Method 2: Deploy Key (Alternative - More Secure)
# 1. On your Pi, generate SSH key: ssh-keygen -t ed25519 -f ~/.ssh/wine_cellar_deploy
# 2. Copy the public key: cat ~/.ssh/wine_cellar_deploy.pub
# 3. In GitHub: Settings -> Deploy keys -> Add deploy key
# 4. Paste the public key and check "Allow write access" if needed
# 5. Set the path to private key below
export DEPLOY_KEY_PATH=""

# For PUBLIC repositories: Leave both GITHUB_TOKEN and DEPLOY_KEY_PATH empty

# ==============================================================================
# TAPO CREDENTIALS - REQUIRED
# ==============================================================================

# Your TP-Link Tapo account credentials
# These are used to connect to your Tapo devices
export TAPO_USERNAME="your_tapo_email@example.com"
export TAPO_PASSWORD="your_tapo_password"

# ==============================================================================
# OPTIONAL CONFIGURATION - CUSTOMIZE IF NEEDED
# ==============================================================================

# System username (default: wladmin)
# This is the username for the Raspberry Pi
export PI_USERNAME="wladmin"

# Client identifier for this installation
# Useful if you have multiple wine cellars
export CLIENT_ID="wine-cellar-001"

# Your timezone (see: timedatectl list-timezones)
export TIMEZONE="Asia/Kuala_Lumpur"

# Network that can access the API (CIDR notation)
# Default allows only local network access
export ALLOWED_NETWORK="192.168.0.0/24"

# Email for system alerts (optional - leave empty if not needed)
export ALERT_EMAIL=""

# ==============================================================================
# ADVANCED CONFIGURATION - USUALLY NO NEED TO CHANGE
# ==============================================================================

# API port (internal - nginx will proxy from port 80)
export API_PORT="3000"

# Log level (DEBUG, INFO, WARNING, ERROR)
export LOG_LEVEL="WARNING"

# Monitor interval in seconds (how often to check devices)
export MONITOR_INTERVAL="30"

# UI refresh interval in seconds
export UI_REFRESH_INTERVAL="5"

# ==============================================================================
# DO NOT MODIFY BELOW THIS LINE
# ==============================================================================

# Auto-generated secure API secret
export API_SECRET="wine-cellar-secret-$(openssl rand -hex 16)-$(date +%s)"

# Installation timestamp
export INSTALL_DATE="$(date)"

echo "Configuration loaded successfully!"
