The reason for this is to keep your local IP assigned by the router the same, though this shouldn’t change your router can assign a different IP on restarts, which can make port forwarding rules ineffective.

## Set Static Local IP Via UI

Your router will change the local IP on occasion, and port forwarding rules are added to the specific local IP of the device. To ensure that the port forwarding rules do not become ineffective and lose access, you need to set the local IP to be fixed.

Identify IP, look for wired connection. This is usually ‘eth0’ if not it should start with ‘192.168.0’ for a local IP.

```
ip addr show
```
<img width="493" alt="PIC 1" src="https://github.com/GLCNI/RPC-node-deployments/assets/67609618/a785852c-c0fc-4410-8ebb-4a0e5d79f765">

In my case, the local IP is `192.168.0.50` and Ethernet interface name is `enp4s0`

Using UI
`Settings > Network > Wired`

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/4b1157ff-d63c-4f11-97ac-dfcdc73ca224)


**Address:** 192.168.0.50  
the current local IP, this can be changed if desired.

**Netmask:** 255.255.255.0  
common netmask 255.255.255.0 is used for a class C network, which allows for up to 254 hosts (devices) in the network.

**Gateway:** This should be your router's IP address. This is typically 192.168.0.1 or 192.168.1.1. You can confirm this by checking your router settings or using the command `ip route | grep default` in the terminal.

**DNS:** Unset ‘Automatic’ and enter manually. 

For Cloudflare 
```
1.1.1.1, 1.0.0.1
```
Cloudflare has a lot of benefits regards to speed and privacy, if configuring sub-domains with Cloudflare it makes sense to use this.

For Google
```
8.8.8.8, 8.8.4.4
```

Once these settings have been applied restart the system to take effect

test that the DNS is resolving domain names correctly `ping google.com` should work the same as `ping 8.8.8.8` if not then it suggests a DNS issue.

The UI and system is using `NetworkManager` for DNS management.
```
sudo systemctl status NetworkManager
```

## Option 2: Manually configure

Manually configure NetworkManager via command line

1.	Navigate to the NetworkManager connections directory:
```
cd /etc/NetworkManager/system-connections/
ls
```

This will display the available connections, for example “Wired connection 1.nmconnection”

2.	Backup current configuration: (to revert back if this does not work)

```
sudo cp 'Wired connection 1.nmconnection' 'Wired connection 1.nmconnection.backup'
```

3.	Edit Configuration
```
sudo nano 'Wired connection 1.nmconnection'
```

Under [ipv4], set:

```
[ipv4]
address1=192.168.0.50/24,192.168.0.1
dns=1.1.1.1;1.0.0.1;
```

4.	Restart NetworkManager
```
sudo systemctl restart NetworkManager
```


