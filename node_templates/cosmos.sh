#!/bin/bash

#update device
sudo apt update && sudo apt upgrade -y

####################
### DEPENDANCIES ###
####################

#install dependancies
sudo apt install git wget jq gcc build-essential ufw curl snapd make tar clang pkg-config libssl-dev –y

#install go
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.20.3
source $HOME/.bashrc

#check go is installed, exit if it did not install
GO_VERSION=$(go version 2> /dev/null)
if [ $? -eq 0 ]; then
    echo "Go is installed successfully: ${GO_VERSION}"
else
    echo "Something went wrong with installing Go"
    exit 1
fi

#####################
### SET VARIABLES ###
#####################

# Set current working directory
export COSMO_HOMEDIR="$(pwd)"
echo "export COSMO_HOMEDIR=$COSMO_HOMEDIR" >> "$HOME/.bashrc"

# node name
read -p "Enter node name: " NODENAME
echo "export NODENAME=$NODENAME" >> "$HOME/.bashrc"

# Snapshot URL
echo "this install uses quicksync (snapshot) data, you can find a snapshot for this chain here 'https://quicksync.io/networks/cosmos.html' "
echo "copy the download URL for what best applies (cosmoshub-4-pruned)"
echo "there are other comunity hosted snapshots which can also be used" 
read -p "Enter URL for snapshot data: " SNAPURL
echo "export SNAPURL=$SNAPURL" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

######################
### GAIA binary ###
######################

#install gaia
cd $HOME
git clone -b v10.0.1 https://github.com/cosmos/gaia.git
cd gaia
make install


# Initiate node
gaiad init $NODENAME
# get genesis
wget https://raw.githubusercontent.com/cosmos/mainnet/master/genesis/genesis.cosmoshub-4.json.gz
gzip -d genesis.cosmoshub-4.json.gz
mv genesis.cosmoshub-4.json ~/.gaia/config/genesis.json

#set seeds and peers

#get addrbook
wget https://dl2.quicksync.io/json/addrbook.cosmos.json
mv addrbook.cosmos.json ~/.gaia/config/addrbook.json

#########################
### cosmovisor binary ###
#########################

cd
mkdir -p ~/.gaia/cosmovisor/genesis/bin
mkdir -p ~/.gaia/cosmovisor/upgrades/v10/bin

#install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

#copy binary to cosmovisor
cp $GOPATH/bin/gaiad ~/.gaia/cosmovisor/genesis/bin
cp $GOPATH/bin/gaiad ~/.gaia/cosmovisor/upgrades/v10/bin/

#########################
##### snapshot data #####
#########################

#download snapshot 
sudo apt-get install liblz4-tool aria2 -y
cd $HOME/.gaia/
wget -O - $SNAPURL | lz4 -d | tar -xvf -

#########################
### create service #####
#########################

#create system service file 
sudo tee /etc/systemd/system/cosmovisor.service > /dev/null <<EOF  
[Unit]
Description=Gaia Daemon
After=network-online.target

[Service]
Environment="DAEMON_HOME=$HOME/.gaia"
Environment="DAEMON_NAME=gaiad"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

#start service 
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor
sudo systemctl start cosmovisor
