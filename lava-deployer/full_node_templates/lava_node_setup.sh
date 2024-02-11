#!/bin/bash

echo "About this build:"
echo "This build uses Snapshot" 
echo "Run with or without cosmovisor to run chain upgrades with AUTO DOWNLOAD set to true"
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."
echo ""
echo "Setup Considerations:"
echo "You will need to Open Ports:"
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

# Update device
sudo apt update && sudo apt upgrade -y

# Install dependencies 
sudo apt install git curl wget tar unzip jq build-essential pkg-config clang bsdmainutils make ncdu gcc snapd libssl-dev -y

# Install Go
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.20.5

# Set GOROOT and GOPATH, update PATH
export GOROOT=$HOME/.go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH

# Check if Go is installed, exit if it did not install
if command -v go > /dev/null; then
    echo "Go is installed successfully: $(go version)"
else
    echo "Something went wrong with installing Go"
    exit 1
fi

echo "Necessary dependencies including Go have been installed."
read -n 1 -p "Press any key to continue or Ctrl+C to cancel..."


#####################
### SET VARIABLES ###
#####################

echo "Enter a name for your node:"
read -p "Name: " LAVA_MONIKER
echo "You have entered: $LAVA_MONIKER"
echo "export LAVA_MONIKER=$LAVA_MONIKER" >> "$HOME/.bashrc"

# OTHER VAIRABLES  HERE

######################
### LAVA binary ###
######################

# Define Binary type 
export LAVA_BINARY=lavad
echo "export LAVA_BINARY=$LAVA_BINARY" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# install lavad
cd $HOME
git clone https://github.com/lavanet/lava.git
cd lava
git checkout v0.34.0
make install

# LAVA CLI
lavad config chain-id lava-testnet-2
lavad config keyring-backend test


######################
# Optional: Add Wallet
######################

echo "Do you want to create or recover a wallet? (yes/no)"
read -p "Enter choice (yes or no): " WALLET_CREATE_CHOICE

if [ "$WALLET_CREATE_CHOICE" = "yes" ]; then
    echo "Enter a name for a wallet:"
    read -p "Name: " LAVA_WALLET
    echo "You have entered: $LAVA_WALLET"
    echo "export LAVA_WALLET=$LAVA_WALLET" >> "$HOME/.bashrc"
    source "$HOME/.bashrc"

    echo "Do you want to:"
    echo "1. Create a new wallet (new seed)"
    echo "2. Recover wallet from existing seed"
    read -p "Enter choice (1 or 2): " WALLET_CHOICE

    case $WALLET_CHOICE in
        1)
            echo "Creating a new wallet..."
            lavad keys add $LAVA_WALLET --keyring-backend test
            echo "Please record your seed phrase securely. Press any key once done."
            read -n 1 -s -r  # Wait for user input
            ;;
        2)
            echo "Recovering wallet from seed..."
            lavad keys add $LAVA_WALLET --keyring-backend test --recover
            ;;
        *)
            echo "Invalid option selected. Exiting."
            exit 1
            ;;
    esac
elif [ "$WALLET_CREATE_CHOICE" = "no" ]; then
    echo "Skipping wallet creation."
else
    echo "Invalid choice. Exiting."
    exit 1
fi

######################
# CONFIGURATIONS
######################

# Initialize node
lavad init $LAVA_MONIKER --chain-id lava-testnet-2

# get genesis
wget -O $HOME/.lava/config/genesis.json "https://raw.githubusercontent.com/lavanet/lava-config/main/testnet-2/genesis_json/genesis.json"

# set min gas
sed -i -e 's|^minimum-gas-prices = ".*"|minimum-gas-prices = "0ulava"|' $HOME/.lava/config/app.toml

# Get seeds 

# Get addressbook
curl -Ls https://snapshots.kjnodes.com/lava-testnet/addrbook.json > $HOME/.lava/config/addrbook.json

######################
### Snapshot   ###
######################

echo "This current build uses snapshot"
echo "syncing the chain from genesis can take weeks"
echo "a number of providers can host this, check discord to find more"
# Later: option to sync chain from genesis with cosmovisor

# SNAPSHOT SELECTION
echo -n "select snapshot (1 - Default kjnodes, 2 - enter custom url) > "
read selectsnapshot
echo
if test "$selectsnapshot" == "1"
then
    sudo apt install snapd -y
    sudo snap install lz4 
    curl -L https://snapshots.kjnodes.com/lava-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.lava
elif test "$selectsnapshot" == "2"
then
    # GET URL
    read -p "Enter URL for snapshot data: " SNAPSHOT_URL
    echo "export SNAPSHOT_URL=$SNAPSHOT_URL" >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    # Extract the extension from the URL
    SNAPSHOT_EXT="${SNAPSHOT_URL##*.}"
    # Handle different extensions
    case $SNAPSHOT_EXT in
        lz4)
            sudo apt install snapd -y
            sudo snap install lz4 
            echo "Downloading and extracting LZ4 compressed snapshot..."
            curl -L $SNAPSHOT_URL | tar -Ilz4 -xf - -C $HOME/.lava
            ;;
        gz)
            echo "Downloading and extracting GZ compressed snapshot..."
            wget -c $SNAPSHOT_URL -O - | tar -xz -C $HOME/.lava
            ;;
        *)
            echo "Unsupported file extension. Exiting."
            exit 1
            ;;
    esac
else
    echo "Invalid selection. Exiting"
    exit 1
fi

######################
## Pruning Settings 
######################

# Apply kjnodes settings if the default kjnodes snapshot was selected
if test "$selectsnapshot" == "1"
then
    # Editing $HOME/.lava/config/app.toml
    sed -i 's/^pruning =.*/pruning = "custom"/' $HOME/.lava/config/app.toml
    sed -i 's/^pruning-keep-recent =.*/pruning-keep-recent = "100"/' $HOME/.lava/config/app.toml
    sed -i 's/^pruning-keep-every =.*/pruning-keep-every = "0"/' $HOME/.lava/config/app.toml
    sed -i 's/^pruning-interval =.*/pruning-interval = "19"/' $HOME/.lava/config/app.toml

    # Editing $HOME/.lava/config/config.toml
    sed -i 's/^indexer =.*/indexer = "null"/' $HOME/.lava/config/config.toml
fi

# Provide options for default or custom settings if a custom snapshot was selected
if test "$selectsnapshot" == "2"
then
    echo "Select pruning settings:"
    echo "1. Use default settings (no changes)"
    echo "2. Enter custom pruning settings"
    read -p "Enter choice (1 or 2): " PRUNING_CHOICE

    case $PRUNING_CHOICE in
        1)
            # Default settings - Do nothing
            ;;
        2)
            # Custom settings
            echo "Enter custom pruning settings:"
            read -p "Enter pruning-keep-recent value: " KEEP_RECENT
            read -p "Enter pruning-keep-every value: " KEEP_EVERY
            read -p "Enter pruning-interval value: " INTERVAL

            # Editing $HOME/.lava/config/app.toml for custom settings
            sed -i 's/^pruning =.*/pruning = "custom"/' $HOME/.lava/config/app.toml
            sed -i "s/^pruning-keep-recent =.*/pruning-keep-recent = \"$KEEP_RECENT\"/" $HOME/.lava/config/app.toml
            sed -i "s/^pruning-keep-every =.*/pruning-keep-every = \"$KEEP_EVERY\"/" $HOME/.lava/config/app.toml
            sed -i "s/^pruning-interval =.*/pruning-interval = \"$INTERVAL\"/" $HOME/.lava/config/app.toml

            # Editing $HOME/.lava/config/config.toml for custom settings
            sed -i 's/^indexer =.*/indexer = "null"/' $HOME/.lava/config/config.toml
            ;;
        *)
            echo "Invalid pruning choice. Exiting."
            exit 1
            ;;
    esac
fi

######################
## Setup Node Service
######################

echo "Select the method to setup the node service:"
echo "1. Setup without cosmovisor"
echo "2. Setup with cosmovisor"
read -p "Enter choice (1 or 2): " NODE_SERVICE_CHOICE

case $NODE_SERVICE_CHOICE in
    1)
        # Setup without cosmovisor
        sudo tee /etc/systemd/system/lavad.service > /dev/null <<EOF
[Unit]
Description=LAVA\n
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which lavad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable lavad
        sudo systemctl start lavad
        ;;
    2)
        # Setup with cosmovisor

        # create cosmovisor directories
        mkdir -p $HOME/.lava/cosmovisor/genesis/bin
        mkdir -p $HOME/.lava/cosmovisor/upgrades/v0.34.0/bin

        # install cosmovisor
        go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

        # copy binaries to cosmovisor
        cp $GOPATH/bin/lavad $HOME/.lava/cosmovisor/genesis/bin
        cp $GOPATH/bin/lavad $HOME/.lava/cosmovisor/upgrades/v0.34.0/bin/

        # setup system service
        sudo tee /etc/systemd/system/cosmovisor.service > /dev/null <<EOF
[Unit]
Description=lava Daemon (cosmovisor)
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_NAME=lavad"
Environment="DAEMON_HOME=$HOME/.lava"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable cosmovisor
        sudo systemctl start cosmovisor
        ;;
    *)
        echo "Invalid option selected. Exiting."
        exit 1
        ;;
esac

######################
## RPC Settings
######################

# Open Ports - must be done manually by user

# Stop the appropriate service based on NODE_SERVICE_CHOICE
if [ "$NODE_SERVICE_CHOICE" = "1" ]; then
    sudo systemctl stop lavad
elif [ "$NODE_SERVICE_CHOICE" = "2" ]; then
    sudo systemctl stop cosmovisor
fi

# Open RPC
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/laddr =/s/= .*/= "tcp:\/\/0.0.0.0:26657"/}' $HOME/.lava/config/config.toml
# Reset grpc_laddr to empty value
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/grpc_laddr =/s/= .*/= ""/}' $HOME/.lava/config/config.toml
# Reset pprof_laddr to default
sed -i '/^\[rpc\]$/,/^\[.*\]$/{/pprof_laddr =/s/= .*/= "localhost:6060"/}' $HOME/.lava/config/config.toml

# Edit REST API settings
sed -i '/\[api\]/,/^\[.*\]/{/enable =/s/=.*/= true/; /swagger =/s/=.*/= false/; /address =/s/=.*/= "tcp:\/\/0.0.0.0:1317"/}' $HOME/.lava/config/app.toml

# Editing gRPC settings
sed -i '/\[grpc\]/,/^\[.*\]/{/enable =/s/=.*/= true/; /address =/s/=.*/= "tcp:\/\/0.0.0.0:9090"/}' $HOME/.lava/config/app.toml

# Start the appropriate service based on NODE_SERVICE_CHOICE
if [ "$NODE_SERVICE_CHOICE" = "1" ]; then
    sudo systemctl daemon-reload
    sudo systemctl restart lavad
elif [ "$NODE_SERVICE_CHOICE" = "2" ]; then
    sudo systemctl daemon-reload
    sudo systemctl restart cosmovisor
fi
