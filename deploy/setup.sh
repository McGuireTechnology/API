#!/bin/bash

# Initial Setup Script for Digital Ocean Droplet
# Run this script once to set up the server for the first time

set -e

echo "🔧 Setting up Digital Ocean Droplet for McGuire Technology API..."

# Configuration
APP_NAME="mcguire-api"
APP_DIR="/var/www/${APP_NAME}"
DOMAIN="api.mcguire.technology"
REPO_URL="${REPO_URL:-https://github.com/McGuireTechnology/API.git}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@mcguire.technology}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Configuration:${NC}"
echo "  App Directory: ${APP_DIR}"
echo "  Domain: ${DOMAIN}"
echo "  Admin Email: ${ADMIN_EMAIL}"
echo ""

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "📦 Installing required packages..."
apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    nginx \
    git \
    curl \
    certbot \
    python3-certbot-nginx \
    ufw \
    fail2ban

echo -e "${GREEN}✓ System packages installed${NC}"

# Install Poetry
echo "📦 Installing Poetry..."
curl -sSL https://install.python-poetry.org | python3 -
export PATH="/root/.local/bin:$PATH"
echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc

echo -e "${GREEN}✓ Poetry installed${NC}"

# Configure firewall
echo "🔒 Configuring firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw status

echo -e "${GREEN}✓ Firewall configured${NC}"

# Clone repository
echo "📥 Cloning repository..."
if [ ! -d "${APP_DIR}" ]; then
    mkdir -p /var/www
    git clone ${REPO_URL} ${APP_DIR}
else
    echo "  Directory already exists, pulling latest changes..."
    cd ${APP_DIR}
    git pull
fi

cd ${APP_DIR}

echo -e "${GREEN}✓ Repository cloned${NC}"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
/root/.local/bin/poetry install --only main --no-interaction

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Set up environment file
echo "⚙️  Setting up environment file..."
if [ ! -f "${APP_DIR}/.env" ]; then
    cat > ${APP_DIR}/.env << EOF
APP_NAME=McGuire Technology API
APP_VERSION=0.1.0
ENVIRONMENT=production
DEBUG=false
API_HOST=0.0.0.0
API_PORT=8000
ALLOWED_ORIGINS=https://mcguire.technology,https://www.mcguire.technology
EOF
    echo -e "${YELLOW}⚠️  Please update .env file with your configuration${NC}"
fi

echo -e "${GREEN}✓ Environment file created${NC}"

# Set up systemd service
echo "⚙️  Setting up systemd service..."
cp ${APP_DIR}/deploy/mcguire-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ${APP_NAME}
systemctl start ${APP_NAME}

echo -e "${GREEN}✓ Systemd service configured${NC}"

# Set up Nginx
echo "⚙️  Setting up Nginx..."
cp ${APP_DIR}/deploy/nginx.conf /etc/nginx/sites-available/${DOMAIN}
ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/

# Remove default Nginx site
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration (temporarily comment out SSL lines for initial setup)
sed -i 's/ssl_certificate/#ssl_certificate/g' /etc/nginx/sites-available/${DOMAIN}
sed -i 's/include \/etc\/letsencrypt/#include \/etc\/letsencrypt/g' /etc/nginx/sites-available/${DOMAIN}

nginx -t
systemctl restart nginx

echo -e "${GREEN}✓ Nginx configured${NC}"

# Set up SSL with Let's Encrypt
echo "🔒 Setting up SSL certificates..."
echo -e "${YELLOW}Note: Make sure your domain DNS is pointing to this server before continuing${NC}"
read -p "Continue with SSL setup? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${ADMIN_EMAIL}
    
    # Restore original Nginx config
    cp ${APP_DIR}/deploy/nginx.conf /etc/nginx/sites-available/${DOMAIN}
    nginx -t
    systemctl reload nginx
    
    echo -e "${GREEN}✓ SSL certificates installed${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping SSL setup. Run certbot manually when ready${NC}"
fi

# Set up log rotation
echo "📝 Setting up log rotation..."
cat > /etc/logrotate.d/${APP_NAME} << EOF
/var/log/nginx/${DOMAIN}*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
EOF

echo -e "${GREEN}✓ Log rotation configured${NC}"

# Set permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data ${APP_DIR}
chmod -R 755 ${APP_DIR}

echo -e "${GREEN}✓ Permissions set${NC}"

# Print status
echo ""
echo "=========================================="
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo "=========================================="
echo ""
echo "Service status:"
systemctl status ${APP_NAME} --no-pager
echo ""
echo "Nginx status:"
systemctl status nginx --no-pager
echo ""
echo "🌐 Your API should now be accessible at:"
echo "   http://${DOMAIN}"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   https://${DOMAIN}"
fi
echo ""
echo "📝 Next steps:"
echo "   1. Update .env file with your configuration"
echo "   2. Restart the service: systemctl restart ${APP_NAME}"
echo "   3. Check logs: journalctl -u ${APP_NAME} -f"
echo ""
