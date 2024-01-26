#!/bin/bash

# Check Open Ports
echo "this device will host the NGINX/certificate server"
echo "this needs Ports: 443 and 80 open"
echo "If you have not done so, then do this before continuing!"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..." key
# Clear the screen to avoid displaying escape characters
clear

# Open port 443 default https
# sudo ufw allow https
# Open port 80 default http
# sudo ufw allow http

# Check current node $NODETYPE, Variable stored in .bashrc
source "$HOME/.bashrc"
echo "You are running a $NODETYPE node"
echo "You must secure a Domain, this can be done on Cloudflare or similar, for more detailed instructions see LINK"
read -n 1 -s -r -p "Press any key to continue or Ctrl+C to cancel..." key
# Clear the screen again
clear

# Enter Sub-domain
echo "Enter your secured domain including the extension, example: <DOMAIN-NAME>.io"
# Clear the input buffer before reading the domain name
while read -r -t 0; do read -r; done
read -p "Enter domain: " DOMAIN_NAME
echo "export DOMAIN_NAME=$DOMAIN_NAME" >> "$HOME/.bashrc"

echo "Create an A record with the name $NODETYPE"
echo "Example: $DOMAIN_NAME that will resolve to sub-domain $NODETYPE.$DOMAIN_NAME"
echo "You will need to point to this device IP"
read -n 1 -s -r -p "Press any key to continue or Ctrl+C to cancel..." key
# Final clear to clean up any residual input
clear

# Install NGINX
sudo apt update
sudo apt install certbot net-tools nginx python3-certbot-nginx -y

# Create NGINX configuration file
NGINX_CONFIG="/etc/nginx/sites-available/$NODETYPE.$DOMAIN_NAME"
sudo tee "$NGINX_CONFIG" > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME $NODETYPE.$DOMAIN_NAME;

    location / {
        root /var/www/html;
        try_files \$uri \$uri/ =404;
    }

    location ~ /.well-known/acme-challenge {
        allow all;
        root /var/www/html;
    }
}
EOF

# Restart NGINX
sudo systemctl restart nginx

# Create a symbolic link to the sites-enabled directory
sudo ln -s "$NGINX_CONFIG" /etc/nginx/sites-enabled/

echo "Challenge configuration for sub-domain has been created, next step will generate certificates"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."

# generate certificate challenge
sudo certbot certonly --register-unsafely-without-email -d $NODETYPE.$DOMAIN_NAME

# Path to the NGINX configuration file
NGINX_CONFIG="/etc/nginx/sites-available/$NODETYPE.$DOMAIN_NAME"

# Overwrite the NGINX configuration file with the new configuration
sudo tee "$NGINX_CONFIG" > /dev/null << EOF
server {
    listen 443 ssl http2;
    server_name $NODETYPE.$DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$NODETYPE.$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$NODETYPE.$DOMAIN_NAME/privkey.pem;
    error_log /var/log/nginx/debug.log debug;

    location / {
        proxy_pass http://127.0.0.1:26657; # Directly pointing to cosmos node RPC API port
    }
}
EOF

# Restart NGINX to apply the new configuration
sudo systemctl restart nginx