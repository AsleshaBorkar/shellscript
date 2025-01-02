#!/bin/bash

# Variables
GITHUB_URL="https://github.com/panda98r/docker-spring-boot-java-web-service-example.git"
APP_DIR="/var/www/html/springboot"
CLONE_DIR="/tmp/springboot"
NGINX_CONF="/etc/nginx/sites-available/springboot"
NGINX_SYMLINK="/etc/nginx/sites-enabled/springboot"
JAR_NAME="docker-java-app-example.jar"

# Install necessary packages
echo "Updating system packages..."
sudo apt update -y
sudo apt install -y openjdk-17-jdk maven git nginx

# Clone the repository
echo "Cloning repository from $GITHUB_URL..."
if [ -d "$CLONE_DIR" ]; then
    sudo rm -rf "$CLONE_DIR"
fi
git clone "$GITHUB_URL" "$CLONE_DIR"

# Build the application using Maven
echo "Building the application..."
cd "$CLONE_DIR" || exit
mvn clean package

# Deploy the application
echo "Deploying the application to $APP_DIR..."
if [ -d "$APP_DIR" ]; then
    sudo rm -rf "$APP_DIR"
fi
sudo mkdir -p "$APP_DIR"
sudo cp -r "$CLONE_DIR/target/"* "$APP_DIR"

# Start the Spring Boot application
echo "Starting the Spring Boot application..."
JAR_PATH="$APP_DIR/$JAR_NAME"
sudo nohup java -jar "$JAR_PATH" > /dev/null 2>&1 &

# Configure Nginx reverse proxy
echo "Configuring Nginx..."
# Create the Nginx configuration for the Spring Boot application
#sudo bash -c "cat > $NGINX_CONF <<EOF
#server {
#    listen 80;
#    server_name localhost;

#    location / {
#        proxy_pass http://127.0.0.1:8080;  # Forward requests to the Spring Boot app
#        proxy_set_header Host \$host;
#        proxy_set_header X-Real-IP \$remote_addr;
#        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto \$scheme;
#    }
#}
#EOF"

# Enable the Nginx configuration
echo "Enabling Nginx configuration..."
sudo ln -sf "$NGINX_CONF" "$NGINX_SYMLINK"  # Use `-sf` to force replace if a symlink already exists

# Test Nginx configuration and restart
echo "Testing Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid. Restarting Nginx..."
    sudo systemctl restart nginx
else
    echo "Nginx configuration is invalid. Please check the logs."
    exit 1
fi

# Verify the deployment
echo "The application has been deployed and Nginx is configured. Verify it by accessing http://your-domain-or-ip"

