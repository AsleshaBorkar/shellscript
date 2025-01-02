#!/bin/bash

# Configuration
REPO_URL="https://github.com/panda98r/Angular-HelloWorld.git"
CLONE_DIR="/tmp/angular"
DEPLOY_DIR="/var/www/html/"
NGINX_CONF="/etc/nginx/sites-available/angular"
NGINX_LINK="/etc/nginx/sites-enabled/angular"

echo "Starting deployment process..."

# Clone the repository
echo "Cloning the repository.."
sudo rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

# Navigate to the cloned directory and install dependencies
echo "Installing dependencies..."
cd "$CLONE_DIR"
npm install

# Build the application
echo "Building the application..."
npm run build -- --output-path=dist --base-href=/

# Deploy the build folder
echo "Deploying the application..."
sudo rm -rf "$DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"
sudo cp -r dist/* "$DEPLOY_DIR"


# Enable Nginx configuration
sudo ln -sf "$NGINX_CONF" "$NGINX_LINK"
sudo nginx -t && sudo systemctl start nginx

echo "Deployment completed successfully."
