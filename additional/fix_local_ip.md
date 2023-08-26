The reason for this is to keep your local IP assigned by the router the same, though this shouldn’t change your router can assign a different IP on restarts, which can make port forwarding rules ineffective.

## Set Static Local IP

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

**DNS:** can be left as is, however if you are configuring sub-domains for services then it might make sense to change this to Cloudflare's (1.1.1.1)
