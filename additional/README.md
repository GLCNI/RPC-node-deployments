# Additional Info:

Additional Information surrounding node operations for local node operators.

Such as hardware setup/ installing Linux /networks/ security considerations.

----

[**Hardware Selection:**](https://github.com/GLCNI/RPC-node-deployments/tree/main/additional#hardware-selection) general hardware specifications and recommendations\  
[**Installing Linux:**](https://github.com/GLCNI/RPC-node-deployments/tree/main/additional#installing-linux) How to install Ubuntu 20.04LTS Locally 

[**ssh:**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/ssh.md) how to setup ssh to local devices for remote entry\  
[**fix local ip:**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/fix_local_ip.md) make private/local IP fixed to keep port forwarding rules\  
[**mount additional drives:**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/mount_additional_drives.md) add extra storage for running extra services/nodes\  
[**swap space:**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/swap_space.md) to configure SSD space as extra RAM buffer

**sub-domains:** configure domain routing for external access to mask IP addresses\  
for setting up with docker services see [**traefik**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/sub_domains_traefik.md)\  
for setting up with services running with systemD see [**nginx**](https://github.com/GLCNI/RPC-node-deployments/blob/main/additional/sub_domains_nginx.md)

**Monitoring:** PENDING

----

# Hardware Selection

**Use a Dedicated Device for node operations, thus performance is optimised, and security risks minimised.**

These are general Hardware specifications I have seen across the space for most blockchain node services, to give an idea of what benchmarks when searching for a hardware build, probably the most important is the ability to expand down the line. e.g: Ram Upgradable, Upgradable CPU (something, a laptop or other build may not allow)


### STORAGE:
 
Storage is the likely the most important factor when it comes to Hardware, the reason is write speeds determine how fast you can download chain data and keep in sync, data is constantly being written, with the speeds on HDDs (spinning disk drives) its impossible to ever sync as the chain grows faster than you can catch up.

**Recommended:** **NVMe SSDs**
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/50f09cd2-b5b0-4848-a5e3-cc2fe4753f9c)


**Minimum:** **SSDs higher grade**
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/d865bb64-435c-4b85-8e1c-e5ed02fea420)

Must be high grade performant SSDs, however the cost difference is marginal its best to utilize PCIe M2 slots for NVMe if you have them, as the performance vs cost makes more sense.

Recommended Makes and Models [Here]( https://gist.github.com/yorickdowne/f3a3e79a573bf35767cd002cc977b038)
_(This is for Ethereum Mainnet but is a good reference for reliable brands and models that perform well)_

### RAM:
is a high-speed, short-term storage, applications need space in RAM to operate therefore simultaneous applications will require more RAM space.

**Minimum: 16 GB**

**Recommended: 32GB**


### CPU:

**Minimum: 4core (8 threads)**

generally, most Intel CPU’s i7 and above, as well as more recent i5 models, will meet this requirement. AMD CPUs, most Ryzen 5 and above should comfortably meet this minimum.

**Recommended: 8 core (16 Threads)**


## Other Considerations

**Internet connection: Ethernet cable only**

Don’t waste time with WiFi its simply does not compete with a wired Ethernet connection.

Cat6 round cables are the fastest and best standard for speed (Cat7 is not an official standard)

**Static or Dynamic IPs:**

Your internet provider will typically be a dynamic IP, addresses will change periodically, assigned from a pool by the Internet Service Provider (ISP) or a local network's DHCP server.

A static IP address will be fixed, this is something that can usually be requested from your ISP (usually at extra charge) this is useful for web servers, dedicated services that require constant external access, for RPC node provision services a Static IP will be useful to keep DNS mapping/ ports and firewall settings to specific IP from changing.


# Installing Linux

Most node applications are built around Linux distribution Ubuntu 20.04 LTS

**Step 1: Crete Bootable USB for Ubuntu OS**

Download the ISO image for [Ubuntu 20.04 LTS](https://www.releases.ubuntu.com/focal)

This image must be flashed to a USB using software designed to write OS images to USB drives so they are bootable, such applications are [Balena Etcher]( https://etcher.balena.io/)

**Step 2: Format drive**

**Select Storage Device** to host node application and Linux OS

If its brand new, usually you don’t need to do anything, but if previously used it will need to be formatted.

**Basic format using windows.**

Connect to windows device and find the device identifier on `Disk Management`
_Connecting to a device is easiest via USB but will require an adapter such as NVMe to USB / SATA to USB_

Identify the Disk number (this is important as you do not want to erase a disk in use)

**Open `diskpart` in command line** (can find with the search bar)

```
list disk
```

You should see the same disks from ‘Disk Management’ assuming disk 3 is your desired disk.
```
select disk 3
```

Delete partitions and clean
```
list partition  
select partition 1  
delete partition override  
clean
```

Create Primary partition
```
Create partition primary
list partition
```

You should see one partition now

Format disk  
```
format fs=ntfs quick
```

**Step 3. Install the drive** 

Install to target device, with NVMe this will be an M.2 slot or SSD a Sata connection, if you are unsure check the manual of the motherboard on the storage/hard drive section as there may be multiple slots to install.

**Step 4. Change boot menu**

With the Drive now installed, connect the USB and turn on the device:

Enter Bios settings, depending on make and model can be opened on startup usually by pressing either F1/F2 or F12 keys. This opens the motherboard settings, navigate to ‘boot sequence’ or ‘boot order’, here you need to ensure the USB is top and the SSD you installed is below that and above other options.

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/bebcd94a-9c71-45ea-bfc2-6c894aee29e3)


**Step 5. Install Ubuntu**

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/e9e89f62-ce18-404e-bbdd-cd7198535ab1)

Follow the steps to install.
