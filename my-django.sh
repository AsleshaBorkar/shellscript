#!/bin/bash

# Configuration
PROJECT_DIR="/var/www/html/Django/First_Django_App"
NGINX_CONF="/etc/nginx/sites-available/django.aslesha.site"
NGINX_SYMLINK="/etc/nginx/sites-enabled/django.aslesha.site"
GUNICORN_SERVICE_FILE="/etc/systemd/system/gunicorn.service"
REPO_URL="https://github.com/panda98r/Django.git"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"

# step 1:Check if Nginx is installed,install if not
if ! command nginx -v &> /dev/null;then
echo "Nginx is not installed. Installing......"
sudo apt update
sudo apt install -y nginx
else
echo "Nginx is already installed....."
fi

# step 2: start Nginx service if not running
if ! systemctl is-active --quiet nginx; then
echo "starting Nginx service...."
sudo systemctl start nginx
sudo systemctl enable nginx
else
echo "Nginx service is already running...."
fi

# step 3: Check if Gunicorn is installed,install if not
if ! which gunicorn &> /dev/null; then
echo "Gunicorn is not installed. Installing....."
pip install gunicorn
else
echo "Gunicorn is already installed...."
fi

# step 4: Delete the existing /var/www/html/Django folder
if [ -d "/var/www/html/django" ];then
echo "Deleting existing /var/www/html/Django folder..."
sudo rm -rf /var/www/html/Django
fi

# Create /var/www/html/Django folder
echo "Creating /var/www/html/Django folder...."
sudo mkdir -p /var/www/html/Django

# set permissions to directory
echo "setting permissions for /var/www/html/Django..."
sudo chown -R $USER:$USER /var/www/html/Django
sudo chmod -R 755 /var/www/html/Django

# step 5: Clone the Django project if not already present, or pull the latest changes
if [ ! -d "$PROJECT_DIR" ]; then
echo  "cloning the Django project from GitHub...."
git clone $REPO_URL $PROJECT_DIR
if [ -d "$PROJECT_DIR" ];then
echo "Repository successfully cloned to $PROJECT_DIR..."
else
echo "failed to clone the repository...."
fi
else 
echo "django project is already exists at $PROJECT_DIR. pulling latest changes....
cd $PROJECT_DIR
git pull origin main 
fi

# step 6: Install dependencies from requirements.txt
echo "Installing dependencies from requirements.txt................."
if [ -f "$REQUIREMENTS_FILE" ]; then
    pip install -r $REQUIREMENTS_FILE
else
    echo "Requirements.txt not found. Skipping dependencies installation................"
fi


# Step 7: Modify ALLOWED_HOSTS and Static Files Settings in Django settings

echo "Modifying ALLOWED_HOSTS and static files settings in Django settings..................."

find_settings_file() {
    find $1 -name "settings.py" -type f
}

DJANGO_SETTINGS_FILE=$(find_settings_file "$PROJECT_DIR")

if [ -f "$DJANGO_SETTINGS_FILE" ]; then
    echo "Found settings.py at $DJANGO_SETTINGS_FILE"

    # Update ALLOWED_HOSTS
    if ! grep -q "django.aslesha.site" "$DJANGO_SETTINGS_FILE"; then
        echo "Modifying ALLOWED_HOSTS in $DJANGO_SETTINGS_FILE....................."
        sudo sed -i "s/^ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['django.aslesha.site'\]/" "$DJANGO_SETTINGS_FILE"
    else
        echo "ALLOWED_HOSTS already contains 'django.aslesha.site'......................."
    fi

# Add import os if not already present
    if ! grep -q "import os" "$DJANGO_SETTINGS_FILE"; then
        echo "Adding 'import os' to $DJANGO_SETTINGS_FILE....................."
        sudo sed -i "1i import os" "$DJANGO_SETTINGS_FILE"
    else
        echo "'import os' is already present in $DJANGO_SETTINGS_FILE......................."
    fi
    
     # Add STATIC_URL if not present
    if ! grep -q "STATIC_URL" "$DJANGO_SETTINGS_FILE"; then
        echo "Adding STATIC_URL to $DJANGO_SETTINGS_FILE....................."
        echo "\nSTATIC_URL = '/static/'" | sudo tee -a "$DJANGO_SETTINGS_FILE" > /dev/null
    else
        echo "STATIC_URL is already defined in $DJANGO_SETTINGS_FILE......................."
    fi

    # Add STATIC_ROOT if not present
    if ! grep -q "STATIC_ROOT" "$DJANGO_SETTINGS_FILE"; then
        echo "Adding STATIC_ROOT to $DJANGO_SETTINGS_FILE....................."
        echo "\nSTATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')" | sudo tee -a "$DJANGO_SETTINGS_FILE" > /dev/null
    else
        echo "STATIC_ROOT is already defined in $DJANGO_SETTINGS_FILE......................."

    fi

    # Add STATICFILES_DIRS if not present
    if ! grep -q "STATICFILES_DIRS" "$DJANGO_SETTINGS_FILE"; then
        echo "Adding STATICFILES_DIRS to $DJANGO_SETTINGS_FILE....................."
        echo "\nSTATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]" | sudo tee -a "$DJANGO_SETTINGS_FILE" > /dev/null
    else
        echo "STATICFILES_DIRS is already defined in $DJANGO_SETTINGS_FILE......................."
    fi

    # Add MEDIA_URL and MEDIA_ROOT if not present
    if ! grep -q "MEDIA_URL" "$DJANGO_SETTINGS_FILE"; then
        echo "Adding MEDIA_URL and MEDIA_ROOT to $DJANGO_SETTINGS_FILE....................."
        echo "\nMEDIA_URL = '/media/'" | sudo tee -a "$DJANGO_SETTINGS_FILE" > /dev/null
        echo "MEDIA_ROOT = os.path.join(BASE_DIR, 'media')" | sudo tee -a "$DJANGO_SETTINGS_FILE" > /dev/null
    else
        echo "MEDIA_URL and MEDIA_ROOT are already defined in $DJANGO_SETTINGS_FILE......................."
    fi

else
    echo "settings.py not found in the project directory. Skipping ALLOWED_HOSTS and static files settings modification............................."
fi

echo "Creating static and staticfiles directories if not present and setting permissions................."
mkdir -p "$PROJECT_DIR/First_Django_project/static"
mkdir -p "$PROJECT_DIR/First_Django_project/staticfiles"
mkdir -p "$PROJECT_DIR/First_Django_project/media"

# Set permissions for static directories
echo "Setting permissions for static directories................."
sudo chown -R $USER:$USER "$PROJECT_DIR/First_Django_project/static"
sudo chown -R $USER:$USER "$PROJECT_DIR/First_Django_project/staticfiles"
sudo chmod -R 755 "$PROJECT_DIR/First_Django_project/static"
sudo chmod -R 755 "$PROJECT_DIR/First_Django_project/staticfiles"

sudo chown -R $USER:www-data "$PROJECT_DIR/First_Django_project/media"
sudo chmod -R 755 "$PROJECT_DIR/First_Django_project/media"


# Step 8: Run collectstatic for static files
echo "Collecting static files................."
cd $PROJECT_DIR/First_Django_project
python3 manage.py collectstatic --noinput


# Step 9: Restart Gunicorn service to apply the changes
echo "Checking if Gunicorn is running.........."
if ! systemctl is-active --quiet gunicorn; then
    echo "Gunicorn is not running. Starting Gunicorn service............."
    sudo systemctl daemon-reload
    sudo systemctl restart gunicorn
else
    echo "Gunicorn service is already running............"
fi

# Step 10: Create Nginx configuration file
echo "Creating Nginx configuration file"
sudo tee $NGINX_CONF > /dev/null <<EOL

upstream django_backend {
    server unix:/var/www/html/django/django_project/gunicorn.sock fail_timeout=0;
}

server {
    listen 80;
    server_name django.aslesha.site;

    # Serve static files
    location /static/ {
        alias /var/www/html/Django/First_Django_App/First_Django_project/static/;
    }

    # Serve media files
    location /media/ {
        alias /var/www/html/Django/First_Django_App/First_Djang_project/media/;
    }

    # Proxy requests to the upstream
    location / {
        proxy_pass http://django_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Logs
    access_log /var/log/nginx/django.aslesha.site.access.log;
    error_log /var/log/nginx/django.aslesha.site.error.log;
}
EOL

# Step 11: Create symbolic link to sites-enabled
if [ -L "$NGINX_SYMLINK" ]; then
    echo "Removing existing symbolic link: $NGINX_SYMLINK"
    sudo rm $NGINX_SYMLINK
fi
sudo ln -s $NGINX_CONF $NGINX_SYMLINK

# Step 12: Reload Nginx to apply configuration
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Step 13: Create Gunicorn systemd service file
echo "Creating Gunicorn service file"
sudo chown -R aslesha:www-data /var/www/html/Django/First_Django_App/
sudo chown aslesha:www-data /var/www/html/Django/First_Django_App/First_Django_project/First_Django_project/wsgi.py
sudo chmod 644 /var/www/html/Django/First_Django_App/First_Django_project/First_Django_project/wsgi.py

sudo tee $GUNICORN_SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=gunicorn daemon for First_Django_App
After=network.target

[Service]
User=aslesha
Group=www-data
WorkingDirectory=/var/www/html/Django/First_Django_App/First_Django_project/
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind unix:/var/www/html/Django/First_Django_App/First_Django_project/gunicorn.sock First_Django_project.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

# Step 14: Reload systemd and start Gunicorn service if not already running
echo "Reloading systemd and starting Gunicorn service..."
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
