#!/bin/bash

echo "About this build:"
echo "This build uses Quicksync for Snapshot" 
echo "and cosmovisor to run chain upgrades with AUTO DOWNLOAD set to true"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."
echo ""
echo "Setup Considerations:"
ehco "You will need to Open Ports:"
echo "26656 #P2P / 26657 #RPC / 9090 #grpc / 1317 #REST / (and SSH if needed)"
echo "Setup sufficient Swap space if you have less than 32GB Memory" 
echo "Recommended 32GB / Min: 16GB"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."
echo ""
echo "The next step will install necessary dependencies."
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."

####################
### DEPENDANCIES ###
####################

# update device
sudo apt update && sudo apt upgrade -y

#install dependancies
sudo apt install git wget jq gcc build-essential ufw curl snapd make tar clang pkg-config libssl-dev -y

#install go
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.21.0

# Set GOROOT and GOPATH, update PATH
export GOROOT=$HOME/.go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH

#check go is installed, exit if it did not install
GO_VERSION=$(go version 2> /dev/null)
if [ $? -eq 0 ]; then
    echo "Go is installed successfully: ${GO_VERSION}"
else
    echo "Something went wrong with installing Go"
    exit 1
fi

echo "necessary dependencies including go have been installed."
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."

#####################
### SET VARIABLES ###
#####################

# Store node type
NODETYPE=osmosis
echo "export NODETYPE=$NODETYPE" >> "$HOME/.bashrc"

# node name
read -p "Enter node name: " NODENAME
echo "export NODENAME=$NODENAME" >> "$HOME/.bashrc"

######################
### Osmosis binary ###
######################

# install osmosisd
cd $HOME
git clone https://github.com/osmosis-labs/osmosis
cd osmosis
git checkout v22.0.0
make install

######################
### Configuration ###
######################

# Initiate node
osmosisd init $NODENAME

# Get genesis
wget -O $HOME/.osmosisd/config/genesis.json https://media.githubusercontent.com/media/osmosis-labs/networks/main/osmosis-1/genesis.json

#Get Addrbook (quicksync)
curl -Ls https://dl2.quicksync.io/json/addrbook.osmosis.json > $HOME/.osmosisd/config/addrbook.json

#########################
### cosmovisor binary ###
#########################

cd
mkdir -p ~/.osmosisd/cosmovisor/genesis/bin
mkdir -p ~/.osmosisd/cosmovisor/upgrades/v22/bin

#install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

#copy binary to cosmovisor
cp $GOPATH/bin/osmosisd ~/.osmosisd/cosmovisor/genesis/bin
cp $GOPATH/bin/osmosisd ~/.osmosisd/cosmovisor/upgrades/v22/bin/

#########################
##### snapshot data 
#########################

# snapshot
echo "this build uses snapshot hosted by quicksync"
echo "The next step will download the latest prunned chain data"
echo "This may take a while, but is faster than syncing from Genesis"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."

sudo apt-get update -y
sudo apt-get install liblz4-tool aria2 -y

cd ~/.osmosisd/
SNAPURL=`curl -L https://quicksync.io/osmosis.json|jq -r '.[] |select(.file=="osmosis-1-pruned")|select (.mirror=="Netherlands")|.url'`
wget -O - $SNAPURL | lz4 -d | tar -xvf -

# Snapshot Settings
# ` snapshot-interval = 0`
sed -i 's/^snapshot-interval =.*/snapshot-interval = "0"/' $HOME/.osmosisd/config/app.toml

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
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
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

#######
# Open for RPC
#######

# Open Ports - must be done manually by user

# Stop node
sudo systemctl stop cosmovisor

# Open RPC
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/laddr =/s/= .*/= "tcp:\/\/0.0.0.0:26657"/}' $HOME/.osmosisd/config/config.toml
# Reset grpc_laddr to empty value
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/grpc_laddr =/s/= .*/= ""/}' $HOME/.osmosisd/config/config.toml
# Reset pprof_laddr to default
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/pprof_laddr =/s/= .*/= "localhost:6060"/}' $HOME/.osmosisd/config/config.toml

# Open REST
sed -i '/\[api\]/,/^\[.*\]/{/enable =/s/=.*/= true/; /swagger =/s/=.*/= false/; /address =/s/=.*/= "tcp:\/\/0.0.0.0:1317"/}' $HOME/.osmosisd/config/app.toml

# Open gRPC
sed -i '/\[grpc\]/,/^\[.*\]/{/enable =/s/=.*/= true/; /address =/s/=.*/= "tcp:\/\/0.0.0.0:9090"/}' $HOME/.osmosisd/config/app.toml


# Restart Node with Changes
sudo systemctl daemon-reload
sudo systemctl restart cosmovisor

echo "view logs with: journalctl -u cosmovisor -f"