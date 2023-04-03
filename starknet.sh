#!/bin/bash

# Set the $HOMEDIR variable to the current working directory
export HOMEDIR="$(pwd)"

# INITIAL SETUP
# setup device and dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl -y

# INSTALL DOCKER 
# Check if Docker is already installed
echo "checking if Docker is installed on the system..."
sleep 5
if command -v docker &> /dev/null
then
    echo "Docker is already installed"
else
    # Install Docker
    echo "installing Docker and Docker Compose..."
    sleep 3
    sudo apt-get remove docker docker-engine docker.io containerd runc
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo rm -r get-docker.sh 
    sudo usermod -aG docker $USER && newgrp docker
    echo "Docker is now installed"
fi

# ENTER L1 URL, localhost or custom endpoint 
echo "NOTE: currently pathfinder requires connection to a full archive node to sync"
echo -n "enter URL of L1 node or L1 node is hosted locally on the same device (1 - enter custom URL, 2 - L1 endpoint is hosted locally) > "
read select_rpc_url
echo
if test "$select_rpc_url" == "1"
then
    read -p "Enter L1 URL, the full URL including port if provided: " RPC_URL
    echo "export RPC_URL=$RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url" == "2"
then
    RPC_URL=$"http://localhost:8545"
    echo "export RPC_URL=$RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# create directories for starknet-node
mkdir -p $HOMEDIR/starknet-node/pathfinder
chmod -fR 777 $HOMEDIR/starknet-node/pathfinder
cd starknet-node

# create docker-compose.yml file 
cat << EOF > docker-compose.yml
version: '3.3'
services:
    starknet-node:
        image: 'eqlabs/pathfinder:v0.4.5'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        volumes:
            - $HOMEDIR/starknet-node/pathfinder:/usr/share/pathfinder/data
        ports:
            - '0.0.0.0:9545:9545'
        environment:
            - RUST_LOG=info
            - PATHFINDER_ETHEREUM_API_URL=$RPC_URL
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
EOF

# start docker starknet-node
docker compose up -d
docker compose logs -f starknet-node
