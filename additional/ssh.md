## Setting up SSH

**Install SSH**

SSH should come installed as standard with most Linux distributions to check it is installed.
```
ssh -V
```
if not installed, install with
```
sudo apt update
sudo apt install openssh-client
```

**Install SSH Server**

Check installed.
```
sudo systemctl status ssh or with sudo systemctl status sshd
```
if the service is not present then install with
```
sudo apt update
sudo apt install openssh-server
```

**Change SSH port**

Default port is `22`, should you wish to change this.

```
sudo nano /etc/ssh/sshd_config
```

_note the file name or location may vary._

In the config file uncomment and change `#Port 22` to the desired (unused) port between `1024` and below `65535`

Restart the service.

```
sudo systemctl restart ssh
```

**Firewall**

```
sudo ufw status
sudo ufw allow <port specified in config>
sudo ufw enable
```

### Local Devices: For Local device hosting the following should also be configured:

Should you want to connect externally outside your local network.

**Port Forwarding:**

**Static/fix Local IP:** You should also set a fixed local IP, to avoid port forwarding rules being broken should the router change the IP designation.

**If you really want to open your device to external connections you should also consider**

**Creating SSH Keys**

[How to Setup SSH Keys here:](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/ssh_keys.md)

[https://docs.rocketpool.net/guides/node/securing-your-node.html#essential-secure-your-ssh-access](https://docs.rocketpool.net/guides/node/securing-your-node.html#essential-secure-your-ssh-access)

**Fail2Ban**

[https://docs.rocketpool.net/guides/node/securing-your-node.html#optional-enable-brute-force-and-ddos-protection](https://docs.rocketpool.net/guides/node/securing-your-node.html#optional-enable-brute-force-and-ddos-protection)
