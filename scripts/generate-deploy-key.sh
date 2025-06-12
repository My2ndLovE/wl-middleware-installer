#!/bin/bash
# Helper script to generate GitHub deploy key for Wine Cellar installer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}GitHub Deploy Key Generator${NC}"
echo "============================"
echo ""
echo "This script will help you create a deploy key for accessing"
echo "your private GitHub repository."
echo ""

# Default key name
KEY_NAME="wine_cellar_deploy"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}Deploy key already exists at: $KEY_PATH${NC}"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing key."
        echo ""
        echo -e "${GREEN}Your existing public key:${NC}"
        cat "$KEY_PATH.pub"
        echo ""
        echo -e "${BLUE}Path to use in installer-config.sh:${NC}"
        echo "export DEPLOY_KEY_PATH=\"$KEY_PATH\""
        exit 0
    fi
fi

# Get repository information
echo ""
read -p "Enter your GitHub username: " github_username
read -p "Enter your repository name (without .git): " repo_name

# Generate the key
echo ""
echo -e "${BLUE}Generating SSH key...${NC}"
ssh-keygen -t ed25519 -f "$KEY_PATH" -C "wine-cellar-$github_username" -N ""

# Display the public key
echo ""
echo -e "${GREEN}✅ Deploy key generated successfully!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}IMPORTANT: Follow these steps to add the key to GitHub:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Copy your public key below:"
echo ""
echo -e "${BLUE}-----BEGIN PUBLIC KEY-----${NC}"
cat "$KEY_PATH.pub"
echo -e "${BLUE}-----END PUBLIC KEY-----${NC}"
echo ""
echo "2. Go to: https://github.com/$github_username/$repo_name/settings/keys"
echo ""
echo "3. Click 'Add deploy key'"
echo ""
echo "4. Title: Wine Cellar Pi $(hostname)"
echo ""
echo "5. Paste the public key"
echo ""
echo "6. ✅ Check 'Allow write access' (if you need the Pi to push changes)"
echo ""
echo "7. Click 'Add key'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Add this to your installer-config.sh:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "export DEPLOY_KEY_PATH=\"$KEY_PATH\""
echo ""

# Test the connection (optional)
read -p "After adding the key to GitHub, press Enter to test the connection..."

echo ""
echo -e "${BLUE}Testing GitHub connection...${NC}"

# Add GitHub to known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

# Configure SSH for this test
cat > ~/.ssh/config_temp << SSHEOF
Host github-test
    Hostname github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking no
SSHEOF

# Test connection
if ssh -F ~/.ssh/config_temp -T git@github-test 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ Connection successful! Your deploy key is working.${NC}"
else
    echo -e "${YELLOW}⚠️  Connection test inconclusive. This is normal if you haven't added the key yet.${NC}"
fi

# Cleanup
rm -f ~/.ssh/config_temp

echo ""
echo -e "${GREEN}Setup complete!${NC} You can now run the Wine Cellar installer."
