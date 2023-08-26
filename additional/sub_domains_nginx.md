# Sub-domains with NGINX

The setup will configure Nginx (& TLS certificate) to handle connections to provider node for RPC node services. Nginx will be used to route traffic to specific services based on sub-domains, TLS certificates ensure traffic is secured and authenticated.

**NOTE- example for Juno node:** this guide will be setting up Sub-domain/TLS certificate for a service [juno node]( https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/dr5lUgtMNSyGYpNPzQ8wvKGJYhbHpj7YRkK0uiIQRY4) so ‘juno’ will be used where relevant such as the sub-domain name. Change this name according to whichever service you wish to run (with a sub-domain).

The `<DOMAIN-NAME>` is a placeholder, change to whatever domain name you secure in Step 1. Likewise the `.io` domain extension is an example and should be changed accordingly.

1.	External requests come in on port `443` (HTTPS) to the domain `juno.<domain-name>.io`
2.	Nginx, is listening on port `443`, receives these requests.
3.	Nginx will be configured for these requests to be proxied to the `provider process` listening on port `2221`.
4.	The `provider process` then communicates internally with the `Juno` node on its API ports to fetch the required data or perform the necessary actions.
5.	The response from the Juno node is sent back to the provider process, which then sends it back to Nginx, and Nginx finally sends it back to the external requester.

![DIAGRAM - colors](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/5f064646-4239-4ce5-b968-fae6066a2a34)
_Rough flow of how requests will be routed between services_

## Setting Up a Secure Sub-domain with Nginx: TLS Certificate and Configuration Guide

### Step 1. Secure Sub-domain

**For Cloudflare**

You need a DNS provider such as [Cloudflare]( https://www.cloudflare.com/en-gb/), to manage domains

**Secure Domain**

First you need to secure a Domain, you can do this through Cloudflare, the {DOMAIN-NAME}.io can be anything so long as it is available (not currently in use)

Once a domain has been secured, go to ‘your domains’ select the domain then `DNS > Records > Add Record`

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/c497c5de-8f31-4a87-93f3-7b3d8b5148b9)


**Create an A record** with the name ‘juno’, as this is under the domain `<DOMAIN-NAME>.io` this will resolve to sub-domain `juno.<DOMAIN-NAME>.io`

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/ccd0ffd5-d4f9-42d1-a6b0-9ed536e7df7e)

Change your {SERVER IP} to the public IP of the host machine for the ‘juno’ node and provider process.

### Step 2: install Dependencies

Now a sub-domain has been secured on a DNS provider, its time to setup the corresponding certificate and service for routing requests (Nginx) on the host device for the 'juno' node service. 

First install dependencies required:
```
sudo apt update
sudo apt install certbot net-tools nginx python3-certbot-nginx -y
```

### Step 3. create basic configuration for NGIX

check installed
```
nginx -v
```
check running
```
sudo systemctl status nginx
```
if not ‘running’
```
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Create a Basic configuration for sub-domain certificate:**

first setup a basic configuration that will ensure that the http-01 challenge can be completed to generate the certificate, the server must be reachable and the domain setup and ready.

Ensure that http on Cloudflare is enabled
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/ad9ba702-f8c2-476b-8316-1de25fbf3f8d)


create basic configuration file
```
cd /etc/nginx/sites-available/  
sudo nano {DOMAIN-NAME}_basic
```
enter the following:
```  
server {
    listen 80;
    server_name <DOMAIN-NAME>.io juno.<DOMAIN-NAME>.io;

    location / {
        root /var/www/html;
        try_files $uri $uri/ =404;
    }

    location ~ /.well-known/acme-challenge {
        allow all;
        root /var/www/html;
    }
}
```

Restart Nginx to apply the changes:
```
sudo systemctl restart nginx
```

Ensure your firewall allows HTTP traffic (this will open port 80 the default http port):
```
sudo ufw allow http
```

**Create a symbolic link to the sites-enabled directory:**

```
sudo ln -s /etc/nginx/sites-available/<DOMAIN-NAME>_basic /etc/nginx/sites-enabled/
```

**Remove potential conflicts: (prob not needed)**

the basic nginx config, is more specific to your domains and has the necessary configuration for the Let's Encrypt challenge. A default configuration exists and can be disabled to remove potential conflicts by removing its symlink from `/etc/nginx/sites-enabled`:

```
sudo rm /etc/nginx/sites-enabled/default
```

After making changes, always test the Nginx configuration and then reload or restart Nginx
```
sudo nginx -t
sudo systemctl reload nginx
```

### Step 4. Generate Certificate

Use `certbot` to create a certificate for the `juno` subdomain only,

```
sudo certbot certonly -d juno.<DOMAIN-NAME>.io
```

Select `1` to use Nginx web server plugin when prompted
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/533da28e-3ac6-45b5-995c-64c37bc7fbf3)


You now have the certificate and private key saved at:

```
Certificate: /etc/letsencrypt/live/juno.<DOMAIN-NAME>.io/fullchain.pem
Private Key: /etc/letsencrypt/live/juno. <DOMAIN-NAME>.io/privkey.pem
```

### Step 5. Validate Certificate

```
sudo certbot certificates
```
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/cd85416a-cd02-4d54-b1c3-5a39841de956)


Notice that the certificate is only valid for 90 days from creation, this must be renewed before the certificate expires, this can be done manually or setup up to renew automatically with `cronjob`

### Step 6. Setup Certificate Renewal

Manually you can check the certificate status with:

```
sudo certbot certificates
```

**If renewal is needed**

if close to expire, use `certbot` built in script to renew the certificates before they expire.

```
sudo certbot renew --post-hook "systemctl reload nginx"
```

_`certbot` uses the original configurations for the initial generation so changes to this file (done later) should not affect this renewal, however, you can test the renewal to ensure that `cerbot renew` will work properly, but not make real changes:_

```
sudo certbot renew --dry-run
```

**Automate Renewal**

Setup cronjob to renew (check) certificate twice daily, this is to account for rare situations like revocation
```
sudo crontab -e
```
Enter the following:
```
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew --post-hook "systemctl reload nginx"  
```

### Step 7. Test Sub-domain is working


The provider is not setup yet, which would route requests through this service then to the node service for ‘juno’ _(more detail see diagram at the start of this guide)_

With the provider inactive it would result in an error and render the ‘juno’ node unreachable, a configuration can be created first to bypass the ‘provider’ node just to test the sub-domain works and can be reached externally.

**Edit the config**

```
cd /etc/nginx/sites-available  
nano <DOMAIN-NAME>_basic
```
Enter the following:
```
server {
    listen 443 ssl http2;
    server_name juno. <DOMAIN-NAME>.io;

    ssl_certificate /etc/letsencrypt/live/juno. <DOMAIN-NAME>.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/juno. <DOMAIN-NAME>.io/privkey.pem;
    error_log /var/log/nginx/debug.log debug;

    location / {
        proxy_pass http://127.0.0.1:26657; # Directly pointing to Juno node's RPC API port
    }
}
```

NOTE: The `Proxy_pass` is directly pointing to the ‘Juno’ node RPC port hosted on the same server. If you are hosting a different node this may need to change to the correct RPC API port.

Restart Nginx, to take effect:
```
sudo systemctl restart nginx
```

**Port Forwarding and Firewall settings**

```
sudo ufw allow https  # this opens port 443 default https  
sudo ufw allow http  # this opens port 80 default http, which should have been done earlier
```
Port forward these ports from the router if needed

**Test connection externally**

Now, when you hit `https://juno.<DOMAIN-NAME>.io/status`, Nginx will directly route the request to the Juno node's RPC API on port `26657`.

From another server run the command:
```
curl https://juno.<DOMAIN-NAME>.io:443/status | jq .result.sync_info.catching_up
```
This should return true or false (whether your node is synced or not) but proves that it is externally reachable through the sub-domain URL.
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/f506b9cf-0dd2-48cc-a3e6-75cf92cae74b)



NOTE: this query command is specific to ‘Juno’ node, you should be able to omit the last part and test if the node is reachable or adjust the query to a suitable API for your node.

### Step 8. Add Nginx config for each domain

This part is to setup the config for the `provider` and the node service

Rename file appropriately, add in routing for provider node, and reload nginx once the config is changed:

```
server {
    listen 443 ssl http2;
    server_name juno.<DOMAIN-NAME>.io;

    ssl_certificate /etc/letsencrypt/live/juno.<DOMAIN-NAME>.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/juno.<DOMAIN-NAME>.io/privkey.pem;
    error_log /var/log/nginx/debug.log debug;

    location / {
        proxy_pass http://127.0.0.1:2221; # Assuming the provider node is listening on port 2221
    }
}
```

### Optional: Change Nginx Ports

_if using a local network with shared IP, and wish to setup more than one service on multiple servers you may need to change NGINX default ports to avoid port forwarding conflicts._

To change port for HTTP (port 80) or port for HTTPS (port 443). In Nginx, the port on which the server listens is defined using the listen directive.

Edit config file
```
sudo nano /etc/nginx/sites-available/<your-config-file>
```

for http
```
listen <port>;
```
for https
```
listen <port> ssl http2;
```

Reload nginx
```
sudo systemctl reload nginx
```

Adjust firewall rules accordingly for new ports
