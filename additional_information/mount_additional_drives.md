# Mounting Additional Drives 

Add more SSDs to device for additional storage to host data for other services, this is for running additional services not for increasing storage capacity for one service on the same drive should it need more capacity.

NOTE: you should have suitable base hardware specs to do this, RAM usage will scale with more running services.

**Connect Drive to device**

First physically connect your additional drive/s (SSD) to the motherboard, consult the MB manual for details.

again, should only be dealing with SSDs here, so either a SATA connection or M2 PCIe slot for NVMe drives. Most motherboards have a second M2 slot for an additional drive, and multiple SATA connection points.

**Show disks**

Identify the device name on the system.

```
fdisk -l or lsblk -f
```

lists all connected disks and shows capacity and mountpoints, usually naming is something like `/dev/sda`, `/dev/sdb`, etc. with the partitions on the disk named `/dev/sda1`, `/dev/sda2`, etc.

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/347232c7-139a-483b-b55f-e41a30895d13)


This example has the Linux OS installed on the main drive `nvme1n1`, this was already formatted and partitioned during the install. The SSDs `sda` & `sdb` which were previously used in a Linux device are already formatted and partitioned but do not have ‘mount points’, which means Linux cannot use their storage for file operations yet.

The storage device `nvme0n1` is neither formatted nor partitioned. Storage devices need to be formatted to `ext4`, which is the default filing system for Linux to manage data, and devices need to have a partition to define the storage space within the device.

**Format drive**
Disk name `nvme0n1` is the new drive connected, this device needs to be partitioned and formatted before it can be mounted to the system.

Create Partition
```  
sudo fdisk /dev/nvme0n1
```
---

NOTE: For drives larger than 2TB you should get an error like this:
_Device does not contain a recognised partition table. The size of this disk is 3.7 TiB (4000787030016 bytes). DOS partition table format cannot be used on drives for volumes larger than 2199023255040 bytes for 512-byte sectors. Use GUID partition table format (GPT)._

The message from `fdisk` is indicating that the DOS partition table format (also known as MBR) is not suitable for drives larger than 2TiB. You should use the GPT (GUID Partition Table) instead.

within `fdisk`: type `g` to create a new empty GPT partition table

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/9d937cb5-9372-4c91-9f35-558df4b6c842)


create a new partition by typing `n`, press Enter to accept the default partition number (1), the default first sector, and the default last sector (to use the entire disk).

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/840caa8d-1185-44cb-b1f3-7027b2d82748)


write the partition table to disk and exit, type `w`

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/b94c89a1-33aa-4b3f-b772-5e83f1966599)


This is only for larger than 2TB drives, you can now format the drive in the next step.

-----

Check partition.  
You should now see a partition under the storage device.

![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/ca057d23-d439-46cd-a356-07a5ea797982)


Format drive for Linux  
```
sudo mkfs.ext4 /dev/nvme0n1p1
```
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/b30ac579-7254-47aa-9bdb-7940085c55e5)



**Create mount points.**

```
sudo mkdir -p /mnt/ssd1
sudo mkdir -p /mnt/ssd2
sudo mkdir -p /mnt/nvme2
```

**Mount the partitions.**

```
sudo mount /dev/sda1 /mnt/ssd1
sudo mount /dev/sdb1 /mnt/ssd2
sudo mount /dev/nvme0n1p1 /mnt/nvme2
```

**Make persistent**
These changes to the system need to be made persistent by adding to `/etc/fstab` file, to not lose the mountpoints during reboots.

Access file
```
sudo nano /etc/fstab
```

Add the following.
```
/dev/sda1 /mnt/ssd1 ext4 defaults 0 0
/dev/sdb1 /mnt/ssd2 ext4 defaults 0 0
/dev/nvme0n1p1 /mnt/nvme2 ext4 defaults 0 0
```
