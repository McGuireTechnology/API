#!/bin/bash

# Script to create Digital Ocean Droplet for McGuire Technology API
# Region: NYC3

set -e

echo "🚀 Creating Digital Ocean Droplet for McGuire API..."
echo ""

# Check if doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "❌ doctl is not installed"
    echo ""
    echo "Install it with:"
    echo "  brew install doctl"
    echo ""
    echo "Then authenticate:"
    echo "  doctl auth init"
    echo "  (Get your API token from: https://cloud.digitalocean.com/account/api/tokens)"
    exit 1
fi

# Check if authenticated
if ! doctl account get &> /dev/null; then
    echo "❌ Not authenticated with Digital Ocean"
    echo ""
    echo "Run: doctl auth init"
    echo "Get your API token from: https://cloud.digitalocean.com/account/api/tokens"
    exit 1
fi

echo "✅ doctl installed and authenticated"
echo ""

# Configuration
DROPLET_NAME="mcguire-api"
REGION="nyc3"
SIZE="s-1vcpu-1gb"  # $6/month - 1GB RAM, 1 vCPU, 25GB SSD
IMAGE="ubuntu-22-04-x64"
TAGS="production,api,mcguire"

echo "Configuration:"
echo "  Name: ${DROPLET_NAME}"
echo "  Region: ${REGION}"
echo "  Size: ${SIZE} (\$6/month)"
echo "  Image: ${IMAGE}"
echo ""

# Check for SSH keys
echo "Checking for SSH keys..."
SSH_KEYS=$(doctl compute ssh-key list --format ID --no-header)

if [ -z "$SSH_KEYS" ]; then
    echo "⚠️  No SSH keys found in your Digital Ocean account"
    echo ""
    echo "Add your SSH key:"
    echo "  1. Copy your public key:"
    echo "     cat ~/.ssh/id_ed25519.pub"
    echo ""
    echo "  2. Add it to Digital Ocean:"
    echo "     doctl compute ssh-key create my-key --public-key \"$(cat ~/.ssh/id_ed25519.pub)\""
    echo ""
    read -p "Press Enter after adding your SSH key, or Ctrl+C to cancel..."
    SSH_KEYS=$(doctl compute ssh-key list --format ID --no-header)
fi

echo "✅ Found SSH keys: $SSH_KEYS"
echo ""

# Confirm before creating
read -p "Create droplet? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Creating droplet..."

# Create the droplet
DROPLET_ID=$(doctl compute droplet create ${DROPLET_NAME} \
    --region ${REGION} \
    --size ${SIZE} \
    --image ${IMAGE} \
    --ssh-keys ${SSH_KEYS} \
    --tag-names ${TAGS} \
    --wait \
    --format ID \
    --no-header)

if [ -z "$DROPLET_ID" ]; then
    echo "❌ Failed to create droplet"
    exit 1
fi

echo "✅ Droplet created! ID: ${DROPLET_ID}"
echo ""
echo "Waiting for IP address..."
sleep 5

# Get droplet details
DROPLET_IP=$(doctl compute droplet get ${DROPLET_ID} --format PublicIPv4 --no-header)

echo ""
echo "=========================================="
echo "✅ Droplet Created Successfully!"
echo "=========================================="
echo ""
echo "Details:"
echo "  Name: ${DROPLET_NAME}"
echo "  ID: ${DROPLET_ID}"
echo "  IP: ${DROPLET_IP}"
echo "  Region: ${REGION}"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Configure DNS:"
echo "   Add A record: api.mcguire.technology -> ${DROPLET_IP}"
echo ""
echo "2. Test SSH connection:"
echo "   ssh root@${DROPLET_IP}"
echo ""
echo "3. Run deployment setup:"
echo "   export DROPLET_IP=\"${DROPLET_IP}\""
echo "   export REPO_URL=\"https://github.com/McGuireTechnology/API.git\""
echo "   ssh root@${DROPLET_IP} 'bash -s' < deploy/setup.sh"
echo ""
echo "4. Or manually:"
echo "   ssh root@${DROPLET_IP}"
echo "   git clone https://github.com/McGuireTechnology/API.git /var/www/mcguire-api"
echo "   cd /var/www/mcguire-api"
echo "   bash deploy/setup.sh"
echo ""
echo "Save this IP address: ${DROPLET_IP}"
echo "=========================================="
