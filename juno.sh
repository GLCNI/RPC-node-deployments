#!/bin/bash

#update device
sudo apt update && sudo apt upgrade -y

####################
### DEPENDANCIES ###
####################

#install dependancies
sudo apt-get install make build-essential gcc git jq chrony curl -y

# install go
# Go 1.20.1 required for latest cosmovisor 
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.20.1
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
export JUNO_HOMEDIR="$(pwd)"
echo "export JUNO_HOMEDIR=$JUNO_HOMEDIR" >> "$HOME/.bashrc"

# Set Node Name
read -p "Enter node name: " NODENAME
echo "export NODENAME=$NODENAME" >> "$HOME/.bashrc"


######################
#### JUNO BINARY #####
######################

# Install Juno
git clone https://github.com/CosmosContracts/juno
cd juno
git fetch
git checkout v15.0.0
make install

######################
#### INIT NODE #####
######################

# Initiate node
junod init $NODENAME --chain-id juno-1
# get genesis
wget https://download.dimi.sh/juno-phoenix2-genesis.tar.gz
tar -xvf juno-phoenix2-genesis.tar.gz
mv juno-phoenix2-genesis.json $HOME/.juno/config/genesis.json

######################
# SNAPSHOT & Configs #
######################

# Set SEEDS
# Set the base repo URL for mainnet & retrieve seeds
CHAIN_REPO="https://raw.githubusercontent.com/CosmosContracts/mainnet/main/juno-1"
export SEEDS="$(curl -sL "$CHAIN_REPO/seeds.txt")"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" ~/.juno/config/config.toml

# get addrbook

# SET SNAPSHOT URL
echo "snapshot aids in faster sync by downloading blockchain data from a trusted source"
echo "do you want to use Snapshot y/n "
read response

if [ "$response" = "y" ] || [ "$response" = "Y" ]
then
    echo "Find the latest URL from "https://polkachu.com/tendermint_snapshots/juno" or another community host"
    echo "Enter the URL for the snapshot: "
    read SNAPURL
    echo "The snapshot URL is set to: $SNAPURL"

    # DWN SNAP DATA
    sudo apt install snapd -y
    sudo snap install lz4 
    cd $HOME/.juno
    wget -O - $SNAPURL | lz4 -d | tar -xvf -

    # SET PRUNING CONFIGS
    # Prune Type
    PRUNING="custom"
    # Prune Strategy
    PRUNING_KEEP_RECENT="100"
    PRUNING_KEEP_EVERY="0"
    PRUNING_INTERVAL="10"
    INDEXER="null"
    # Write values to configs
    sed -i.bak -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" ~/.juno/config/app.toml
    sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"/" ~/.juno/config/app.toml
    sed -i.bak -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$PRUNING_KEEP_EVERY\"/" ~/.juno/config/app.toml
    sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"$PRUNING_INTERVAL\"/" ~/.juno/config/app.toml
    sed -i.bak -e "s/^indexer *=.*/indexer = \"$INDEXER\"/" ~/.juno/config/config.toml
else
    echo "Skipping snapshot URL setting."
fi

#########################
### cosmovisor binary ###
#########################

cd
mkdir -p ~/.juno/cosmovisor/genesis/bin
mkdir -p ~/.juno/cosmovisor/upgrades/v15/bin

#install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

#copy binary to cosmovisor
cp $GOPATH/bin/junod ~/.juno/cosmovisor/genesis/bin
cp $GOPATH/bin/junod ~/.juno/cosmovisor/upgrades/v15/bin/


#########################
### create service #####
#########################

#create system service file 
sudo tee /etc/systemd/system/cosmovisor.service > /dev/null <<EOF
[Unit]
Description=Juno Daemon (cosmovisor)
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=junod"
Environment="DAEMON_HOME=$HOME/.juno"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"

[Install]
WantedBy=multi-user.target
EOF

#start service 
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor
sudo systemctl start cosmovisor
