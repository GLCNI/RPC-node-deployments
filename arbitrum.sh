#!/bin/bash

# Check if .bash_profile exists
if [ ! -f "$HOME/.bash_profile" ]; then
    # If not, check if .profile exists
    if [ -f "$HOME/.profile" ]; then
        # If .profile exists, rename it to .bash_profile
        mv "$HOME/.profile" "$HOME/.bash_profile"
    else
        # If neither file exists, create .bash_profile
        touch "$HOME/.bash_profile"
    fi
fi

# Set current working directory
export ARB_HOMEDIR="$(pwd)"
echo "export ARB_HOMEDIR=$ARB_HOMEDIR" >> "$HOME/.bash_profile"
source "$HOME/.bash_profile"

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

# Check Docker version
docker_version=$(docker --version | awk '{print $3}')
docker_compose_version=$(docker compose version | awk '{print $4}')
echo "You are running Docker version $docker_version and Docker Compose version $docker_compose_version"
sleep 5

# VARIABLES
# ABITRUM CHAIN SELECTION
# Run a full node on Arbitrum One or run Arbitrum Nova chain 
echo -n "Run a full node on Arbitrum One or run Arbitrum Nova chain (1 - Arbitrum One, 2 - Arbitrum Nitro, 3 - Nitro Goerli Testnet) > "
read select_arb_chain
echo
if test "$select_arb_chain" == "1"
then
    ARB_CHAIN=$"42161"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_arb_chain" == "2"
then
    ARB_CHAIN=$"42170"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_arb_chain" == "3"
then
    ARB_CHAIN=$"421613"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

#set genesis db snapshot
if [ "$ARB_CHAIN" == "42161" ]
then
    ARB_INIT_URL="https://snapshot.arbitrum.io/mainnet/nitro.tar"
elif [ "$ARB_CHAIN" == "42170" ]
then
    ARB_INIT_URL=""
elif [ "$ARB_CHAIN" == "421613" ]
then
    ARB_INIT_URL="https://snapshot.arbitrum.io/mainnet/nitro.tar"
fi
echo "export ARB_INIT_URL=$ARB_INIT_URL" >> $HOME/.bash_profile
source $HOME/.bash_profile

# ENTER L1 URL PORT
# Default 8545 or custom port or sub-domain not needed to specify
echo -n "is RPC port L1 URL default 8545 not been changed, a custom port, or use of sub-domain/RPC service such as infura/alchemy (1 - default/not changed-8545, 2 - enter custom custom port, 3 - using a service/sub-domain ex: https://infura/url) > "
read select_rpc_url_port
echo
if test "$select_rpc_url_port" == "1"
then
    ARB_L1_RPC_URL_PORT=$"8545"
    echo "export ARB_L1_RPC_URL_PORT=$ARB_L1_RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url_port" == "2"
then
    read -p "Enter port for L1 URL: " ARB_L1_RPC_URL_PORT
    echo "export ARB_L1_RPC_URL_PORT=$ARB_L1_RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url_port" == "3"
then
    ARB_L1_RPC_URL_PORT=$""
    echo "export ARB_L1_RPC_URL_PORT=$ARB_L1_RPC_URL_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# ENTER L1 URL, localhost or custom endpoint 
echo "ensure the L1 node is reachable RPC open and port forwarded if hosted on another device"
echo -n "enter URL of L1 node or L1 node is hosted locally on the same device (1 - enter custom URL, 2 - L1 endpoint is hosted locally) > "
read select_rpc_url
echo
if test "$select_rpc_url" == "1"
then
    read -p "Enter L1 URL, the full URL including port if provided: " ARB_L1_RPC_URL
    echo "export ARB_L1_RPC_URL=$ARB_L1_RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_rpc_url" == "2"
then
    ARB_L1_RPC_URL=$"http://localhost:$ARB_L1_RPC_URL_PORT"
    echo "export ARB_L1_RPC_URL=$ARB_L1_RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# Enter Arbitrum node RPC Port 
echo -n "Define the port to be used for Arbitrum RPC (1 - default 8547, 2 - enter own port) > "
read select_arb_rpc_port
echo
if test "$select_arb_rpc_port" == "1"
then
    ARB_RPC_PORT=$"8547"
    echo "export ARB_RPC_PORT=$ARB_RPC_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_arb_rpc_port" == "2"
then
    read -p "Enter port to be used for Arbitrum RPC: " ARB_RPC_PORT
    echo "export ARB_RPC_PORT=$ARB_RPC_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# create directories for nitro-node
mkdir -p $ARB_HOMEDIR/arbitrum-node/data
chmod -fR 777 $ARB_HOMEDIR/arbitrum-node/data
cd arbitrum-node

# create docker-compose.yml file 
cat << EOF > docker-compose.yml
version: '3.3'
services:
    nitro-node:
        image: 'offchainlabs/nitro-node:latest'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        networks:
          net:
        volumes:
            - '$ARB_HOMEDIR/arbitrum-node/data/:/home/user/.arbitrum'
            - /etc/timezone:/etc/timezone:ro
            - /etc/localtime:/etc/localtime:ro
        ports:
            - '0.0.0.0:8547:8547'
            - '0.0.0.0:8548:8548'
        command:
        - --init.url=$ARB_INIT_URL
        - --l1.url=$RPC_URL
        - --l2.chain-id=42161 
        - --http.api=net,web3,eth,debug
        - --http.corsdomain=*
        - --http.addr=0.0.0.0
        - --http.port=$ARB_RPC_PORT
        - --http.vhosts=*
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
networks:
  net:
    external: true
EOF

# start docker nitro-node
docker compose up -d
echo "           _____  ____ _____ _______ _____  _    _ __  __         _   _  ____  _____  ______"
echo "     /\   |  __ \|  _ \_   _|__   __|  __ \| |  | |  \/  |       | \ | |/ __ \|  __ \|  ____|"
echo "    /  \  | |__) | |_) || |    | |  | |__) | |  | | \  / |       |  \| | |  | | |  | | |__  "
echo "   / /\ \ |  _  /|  _ < | |    | |  |  _  /| |  | | |\/| |       | . ` | |  | | |  | |  __|"
echo "  / ____ \| | \ \| |_) || |_   | |  | | \ \| |__| | |  | |       | |\  | |__| | |__| | |____"
echo " /_/    \_\_|  \_\____/_____| _|_|_ |_|  \_\\____/|_| _|_|___ _  |_| \_|\____/|_____/|______|"
echo "              |_   _|/ ____| |  __ \| |  | | \ | | \ | |_   _| \ | |/ ____|"
echo "                | | | (___   | |__) | |  | |  \| |  \| | | | |  \| | |"
echo "                | |  \___ \  |  _  /| |  | | . ` | . ` | | | | . ` | | |_ |"
echo "               _| |_ ____) | | | \ \| |__| | |\  | |\  |_| |_| |\  | |__| |"
echo "              |_____|_____/  |_|  \_\\____/|_| \_|_| \_|_____|_| \_|\_____|"               
docker compose logs -f nitro-node
