#!/bin/bash

#update device
sudo apt update && sudo apt upgrade -y

####################
### DEPENDANCIES ###
####################

#install dependancies
sudo apt install git wget jq gcc build-essential ufw curl snapd make tar clang pkg-config libssl-dev –y

#install go
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.19.10
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
export OSMO_HOMEDIR="$(pwd)"
echo "export OSMO_HOMEDIR=$OSMO_HOMEDIR" >> "$HOME/.bashrc"

# node name
read -p "Enter node name: " NODENAME
echo "export NODENAME=$NODENAME" >> "$HOME/.bashrc"

# Snapshot URL
echo "this install uses quicksync (snapshot) data, you can find a snapshot for this chain here 'https://quicksync.io/networks/osmosis.html' "
echo "copy the download URL for what best applies (osmosis-1-pruned)"
echo "there are other comunity hosted snapshots which can also be used" 
read -p "Enter URL for snapshot data: " SNAPURL
echo "export SNAPURL=$SNAPURL" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

######################
### Osmosis binary ###
######################

#install osmosisd
cd $HOME
git clone https://github.com/osmosis-labs/osmosis
cd osmosis
git checkout v15.1.2
make install

# Initiate node
osmosisd init $NODE_NAME
# get genesis
wget -O ~/.osmosisd/config/genesis.json https://github.com/osmosis-labs/networks/raw/main/osmosis-1/genesis.json

#########################
### cosmovisor binary ###
#########################

cd
mkdir -p ~/.osmosisd/cosmovisor/genesis/bin
mkdir -p ~/.osmosisd/cosmovisor/upgrades/v15/bin

#install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

#copy binary to cosmovisor
cp $GOPATH/bin/osmosisd ~/.osmosisd/cosmovisor/genesis/bin
cp $GOPATH/bin/osmosisd ~/.osmosisd/cosmovisor/upgrades/v15/bin/

#########################
##### snapshot data #####
#########################

#download snapshot 
sudo apt-get install liblz4-tool aria2 -y
cd $HOME/.osmosisd/
wget -O - $SNAPURL | lz4 -d | tar -xvf -

#########################
### create service #####
#########################

#create system service file 
sudo tee /etc/systemd/system/cosmovisor.service > /dev/null <<EOF
[Unit]
Description=Cosmovisor daemon
After=network-online.target
[Service]
Environment="DAEMON_NAME=osmosisd"
Environment="DAEMON_HOME=$HOME/.osmosisd"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=true"
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
[Install]
WantedBy=multi-user.target
EOF

#start service 
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor
sudo systemctl start cosmovisor
