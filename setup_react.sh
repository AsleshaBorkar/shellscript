#!/bin/bash

# Configuration
REPO_URL="https://github.com/panda98r/react-js-sample.git"
CLONE_DIR="/tmp/react"
DEPLOY_DIR="/var/www/html/"
NGINX_CONF="/etc/nginx/sites-available/react"
NGINX_LINK="/etc/nginx/sites-enabled/react"

echo "Starting deployment process..."

# Clone the repository
echo "Cloning the repository..."
sudo rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

# Navigate to the cloned directory and install dependencies
echo "Installing dependencies..."
cd "$CLONE_DIR"
npm install
echo "inserting new line"
# Build the application
echo "Building the application..."
npm run build

# Deploy the build folder
echo "Deploying the application..."
#sudo rm -rf "$DEPLOY_DIR"
#sudo mkdir -p "$DEPLOY_DIR"
sudo cp -r build/* "$DEPLOY_DIR"

# Nginx Configuration
#echo "Configuring Nginx..."
#sudo tee "$NGINX_CONF" > /dev/null <<EOL
#server {
#    listen 80;
#    server_name localhost _;
#
#    root $DEPLOY_DIR;
#    index index.html;
#
#    location / {
#        try_files \$uri /index.html;
#    }
#
#    error_page 404 /index.html;
#}
#EOL

# Enable Nginx configuration
sudo ln -sf "$NGINX_CONF" "$NGINX_LINK"
sudo nginx -t && sudo systemctl reload nginx

echo "Deployment completed successfully! Visit http://localhost to view your application."
