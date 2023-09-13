# Swap Space

**Swap space** can setup a portion of the SSD as "backup RAM" in case the server runs out of regular RAM, as a backup buffer. Linux generally sets up swap by default and uses by default, as the SSD isn't as fast as RAM, using swap space will slow things down, so it should be set to use as backup buffer only.

32GB RAM is more than suitable for cosmos chains, however it is a good idea to have swap configured to allow a buffer to be used in Storage. Chain upgrades via cosmovisor can be very memory intensive.

**Configure Swap:**

Depending on storage used you can choose to configure 16GB or 32GB and set swappiness parameter to 6 to use swap only when the RAM usage is high.

**Create swap file**

```
sudo fallocate -l 16G /swapfile
```

-------
Warning: If you get an error like this `fallocate: fallocate failed: Text file busy` it means a swapfile exists and is in use, you can confirm this with `sudo swapon --show` to see how much storage it is already configured for (I’ve noticed Ubuntu generally has swap already configured and for 2GB)

If so:

Remove swap file
```
sudo swapoff /swapfile
```

Recreate Swap File
```
sudo fallocate -l 16G /swapfile
```
-------


```
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Make Persistent**

Make permanent across reboots, edit `fstab` file
```
sudo nano /etc/fstab
```
add the following to the file
```
/swapfile none swap sw 0 0
```
*NOTE: if this is already here, then no change is needed*

**Check Swap File:**
```
sudo swapon –show
```
This should return the value set in `swapfile`, ex: 16GB


**Set swappiness Value**

swappiness parameter controls the tendency of the kernel to move processes out of physical memory and onto the swap disk. The value <10 means that the swap space will be used more as an emergency buffer when the RAM is almost fully utilized, and less under normal circumstances.

Cache pressure dictates how quickly the server will delete a cache of its filesystem. with spare RAM `10` will leave the cache in memory for a while, reducing disk I/O.

```
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
