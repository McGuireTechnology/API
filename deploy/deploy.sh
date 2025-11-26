#!/bin/bash

# McGuire Technology API Deployment Script
# This script deploys the API to a Digital Ocean Droplet

set -e

echo "🚀 Starting deployment to Digital Ocean Droplet..."

# Configuration
DROPLET_IP="${DROPLET_IP:-your-droplet-ip}"
DROPLET_USER="${DROPLET_USER:-root}"
APP_NAME="mcguire-api"
APP_DIR="/var/www/${APP_NAME}"
REPO_URL="${REPO_URL:-https://github.com/McGuireTechnology/API.git}"
BRANCH="${BRANCH:-main}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "  Droplet IP: ${DROPLET_IP}"
echo "  User: ${DROPLET_USER}"
echo "  App Directory: ${APP_DIR}"
echo "  Branch: ${BRANCH}"
echo ""

# Check if SSH key is available
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 ${DROPLET_USER}@${DROPLET_IP} exit 2>/dev/null; then
    echo "❌ Cannot connect to droplet. Please check your SSH configuration."
    exit 1
fi

echo -e "${GREEN}✓ SSH connection verified${NC}"

# Deploy the application
ssh ${DROPLET_USER}@${DROPLET_IP} << 'ENDSSH'
set -e

APP_NAME="mcguire-api"
APP_DIR="/var/www/${APP_NAME}"

echo "📦 Updating application code..."
cd ${APP_DIR}

# Pull latest changes
git fetch origin
git checkout ${BRANCH:-main}
git pull origin ${BRANCH:-main}

echo "📦 Installing dependencies..."
/root/.local/bin/poetry install --only main --no-interaction

echo "🔄 Restarting application..."
sudo systemctl restart ${APP_NAME}

echo "⏳ Waiting for application to start..."
sleep 5

# Check if application is running
if systemctl is-active --quiet ${APP_NAME}; then
    echo "✅ Application is running"
    # Test health endpoint
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Health check passed"
    else
        echo "⚠️  Health check failed"
        sudo systemctl status ${APP_NAME}
    fi
else
    echo "❌ Application failed to start"
    sudo systemctl status ${APP_NAME}
    exit 1
fi

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deployment completed successfully!"
ENDSSH

echo -e "${GREEN}✅ Deployment completed!${NC}"
echo ""
echo "Access your API at: https://api.mcguire.technology"
