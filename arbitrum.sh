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
sleep 3
if command -v docker &> /dev/null
then
    echo "Docker is already installed"
else
    # Install Docker
    sudo apt-get remove docker docker-engine docker.io containerd runc
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo rm -r get-docker.sh 
    sudo usermod -aG docker $USER
    newgrp docker
    echo "Docker is now installed"
fi

# Check Docker version
docker_version=$(docker --version | awk '{print $3}')
docker_compose_version=$(docker compose version | awk '{print $3}')
echo "You are running Docker version $docker_version and Docker Compose version $docker_compose_version"
sleep 3

# DEFINE L1 URL PORT
# Default 8545 or custom port or sub-domain not needed to specify
echo -n "is RPC port L1 URL default 8545 not been changed, a custom port, or use of sub-domain/RPC service such as infura/alchemy (1 - default/not changed-8545, 2 - enter custom custom port, 3 - using a service/sub-domain ex: https://infura/url) > "
read select_rpc_url_port
echo
if test "$select_rpc_url_port" == "1"
then
    RPC_URL_PORT=$"8545"
    echo "export RPC_URL_PORT=$RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url_port" == "2"
then
    read -p "Enter port for L1 URL: " RPC_URL_PORT
    echo "export RPC_URL_PORT=$RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url_port" == "3"
then
    RPC_URL_PORT=$""
    echo "export RPC_URL_PORT=$RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# ENTER L1 URL, localhost or custom endpoint 
echo "ensure the L1 node is reachable RPC open and port forwarded if hosted on another device"
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
    RPC_URL=$"http://localhost:$RPC_URL_PORT"
    echo "export RPC_URL=$RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# create directories for nitro-node
mkdir -p /$HOMEDIR/arbitrum-node/data
chmod -fR 777 /$HOMEDIR/arbitrum-node/data
cd arbitrum-node

# create docker-compose.yml file 
cat << EOF > docker-compose.yml
version: '3.3'
services:
    nitro-node:
        network_mode: host
        image: 'offchainlabs/nitro-node:v2.0.11-8e786ec'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        volumes:
            - '/$HOMEDIR/arbitrum-node/data/:/home/user/.arbitrum'	
        ports:
            - '0.0.0.0:8547:8547'
            - '0.0.0.0:8548:8548'
        command:
        - --init.url=https://snapshot.arbitrum.io/mainnet/nitro.tar
        - --l1.url=$RPC_URL
        - --l2.chain-id=42161 
        - --http.api=net,web3,eth,debug 	
        - --http.corsdomain=* 
        - --http.addr=0.0.0.0 
        - --http.vhosts=*
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
EOF

# start docker nitro-node
docker compose up -d
docker compose logs -f nitro-node
