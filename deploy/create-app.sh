#!/bin/bash

# Digital Ocean App Platform Deployment Script
# This script creates a new App Platform application from the configuration

set -e

echo "🚀 McGuire Technology API - App Platform Deployment"
echo "=================================================="
echo ""

# Check if doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "❌ Error: doctl is not installed"
    echo "Please install it: brew install doctl"
    exit 1
fi

# Check if doctl is authenticated
if ! doctl auth list &> /dev/null; then
    echo "❌ Error: doctl is not authenticated"
    echo "Please authenticate: doctl auth init"
    exit 1
fi

# Check if the app spec exists
if [ ! -f ".do/app.yaml" ]; then
    echo "❌ Error: .do/app.yaml not found"
    exit 1
fi

echo "✅ Prerequisites checked"
echo ""

# Validate the app spec
echo "🔍 Validating app specification..."
if ! doctl apps spec validate .do/app.yaml; then
    echo "❌ App specification is invalid"
    exit 1
fi

echo "✅ App specification is valid"
echo ""

# Create the app
echo "📦 Creating App Platform application..."
APP_ID=$(doctl apps create --spec .do/app.yaml --format ID --no-header)

if [ -z "$APP_ID" ]; then
    echo "❌ Failed to create app"
    exit 1
fi

echo "✅ App created successfully!"
echo ""
echo "📋 App Details:"
echo "   App ID: $APP_ID"
echo "   Name: mcguire-api"
echo "   Region: NYC"
echo ""

# Wait for deployment
echo "⏳ Waiting for initial deployment..."
echo "   This may take 5-10 minutes..."
echo ""

# Follow deployment logs
doctl apps logs "$APP_ID" --follow --type BUILD &
LOGS_PID=$!

# Wait for app to be active
while true; do
    STATUS=$(doctl apps get "$APP_ID" --format ActiveDeployment.Phase --no-header)
    
    if [ "$STATUS" = "ACTIVE" ]; then
        echo ""
        echo "✅ Deployment successful!"
        kill $LOGS_PID 2>/dev/null || true
        break
    elif [ "$STATUS" = "ERROR" ] || [ "$STATUS" = "SUPERSEDED" ]; then
        echo ""
        echo "❌ Deployment failed with status: $STATUS"
        kill $LOGS_PID 2>/dev/null || true
        exit 1
    fi
    
    sleep 10
done

# Get app URL
APP_URL=$(doctl apps get "$APP_ID" --format DefaultIngress --no-header)

echo ""
echo "🎉 App Platform deployment complete!"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. View your app:"
echo "   https://cloud.digitalocean.com/apps/$APP_ID"
echo ""
echo "2. Your API is live at:"
echo "   $APP_URL"
echo ""
echo "3. Configure environment secrets (if needed):"
echo "   doctl apps update $APP_ID --spec .do/app.yaml"
echo ""
echo "4. View logs:"
echo "   doctl apps logs $APP_ID --follow --type RUN"
echo ""
echo "5. Custom domain setup:"
echo "   - Add CNAME record: api.mcguire.technology → $APP_URL"
echo "   - SSL certificate will be automatically provisioned"
echo ""
echo "💡 Tip: Future deployments happen automatically when you push to main branch"
echo ""
