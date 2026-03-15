#!/bin/bash
DOMAIN="myapp.local"
WEB_DIR="/var/www/$DOMAIN"
NGINX_CONF_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
NGINX_CONF_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
echo -e "\n[INFO] Starting Nginx Web App Deployment Automation..."
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] This script must be run as root or with sudo."
  exit 1
fi
if [ -d "$WEB_DIR" ]; then
    echo "[INFO] Directory $WEB_DIR already exists. Skipping creation."
else
    echo "[INFO] Creating directory $WEB_DIR..."
    mkdir -p "$WEB_DIR" || { echo "[ERROR] Failed to create directory."; exit 1; }
fi
echo "[INFO] Deploying web application files..."
cat <<INNER_EOF > "$WEB_DIR/index.html"
<!DOCTYPE html>
<html>
<head><title>Welcome to $DOMAIN</title></head>
<body>
    <h1>Successfully deployed $DOMAIN!</h1>
    <p>Automated by DevOps Bash Script</p>
</body>
</html>
INNER_EOF
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"
echo "[INFO] File permissions set successfully."
if [ -f "$NGINX_CONF_AVAILABLE" ]; then
    echo "[INFO] Nginx configuration for $DOMAIN already exists. Skipping creation."
else
    echo "[INFO] Creating new Nginx configuration for $DOMAIN..."
    cat <<INNER_EOF > "$NGINX_CONF_AVAILABLE"
server {
    listen 80;
    server_name $DOMAIN;
    root $WEB_DIR;
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
INNER_EOF
fi
if [ ! -L "$NGINX_CONF_ENABLED" ]; then
    echo "[INFO] Enabling Nginx site..."
    ln -s "$NGINX_CONF_AVAILABLE" "$NGINX_CONF_ENABLED"
fi
if grep -q "$DOMAIN" /etc/hosts; then
    echo "[INFO] Domain $DOMAIN already exists in /etc/hosts. Preventing duplicate."
else
    echo "[INFO] Adding $DOMAIN to /etc/hosts..."
    echo "127.0.0.1   $DOMAIN" >> /etc/hosts
fi
echo "[INFO] Testing Nginx configuration syntax..."
if nginx -t > /dev/null 2>&1; then
    echo "[INFO] Syntax is OK. Reloading Nginx service..."
    systemctl reload nginx || { echo "[ERROR] Failed to reload Nginx."; exit 1; }
else
    echo "[ERROR] Nginx configuration syntax test failed! Please check your config."
    exit 1
fi
echo "[INFO] Performing smoke test..."
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "\n=================================================="
    echo "[SUCCESS] Web application deployed successfully!"
    echo "[SUCCESS] HTTP Status: $HTTP_STATUS (OK)"
    echo "You can access your application at: http://$DOMAIN"
    echo "=================================================="
    exit 0
else
    echo -e "\n[ERROR] Smoke test failed. HTTP Status returned: $HTTP_STATUS"
    exit 1
fi
