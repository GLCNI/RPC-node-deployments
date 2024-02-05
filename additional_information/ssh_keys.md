# Setting up SSH Key Authentication

**1.	Generate SSH Key Pair on the Server**
```
ssh-keygen -t rsa -b 4096
```
This will create a private key (id_rsa) and a public key (id_rsa.pub) in the ~/.ssh/ directory. You can press Enter to all prompts if you want to use the default settings.

**2.	Copy Public Key to Authorized Keys**
```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Set Permissions to Directories
```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**3.	Transfer Private SSH Key**

Securely transfer the private key (id_rsa) to the machine from which you'll be connecting.

**4.	Disable Password login method.**

Passwords can be guessed, brute-forced, or exposed in various ways. Key-based authentication is generally considered more secure than password-based authentication. So to use ‘Only’ the key we created password login needs to be disabled.

Open the SSH Config

```
sudo nano /etc/ssh/sshd_config
```

Edit the following:

1. Uncomment, to allow system to listen over <disired port> on any IP address 
```
ListenAddress 0.0.0.0.
```

2. Uncomment the following to allow PubKey pair authentication
```
PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2
```

3. Disable normal password authentication, Uncomment the line `#PasswordAuthentication yes` and modify to 
```
PasswordAuthentication no
```


**Restart SSH**
```
sudo systemctl restart ssh
```

## How to Connect from external device

Download and install [PuTTYgen](https://putty.org/) on your local machine.

~~Open PuTTYgen and click on Load. Navigate to the location of the id_rsa private key you transferred from the server and open it.
Click on Save private key to save the private key in a format that PuTTY can use (.ppk).~~ 

Edit the file name extension, change to `.ppk` now right click and click `Edit with PuTTYgen` 

Head down to 'Parameters' and make sure the number of bits is correct
![image](https://github.com/GLCNI/RPC-node-deployments/assets/67609618/ae56dbfd-0371-4bf8-a0ac-0f56185d8601)

Once correct, click `Save private key` to save this key in its working format

When connecting with PuTTY, under the Connection > SSH > Auth section, browse and select the .ppk private key file you just saved.

Connect as usual with PuTTY. You won't need to enter a password if the key authentication is successful.
