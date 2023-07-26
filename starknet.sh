#!/bin/bash

#####################################################################################################################
# 1. Install dependancies
#####################################################################################################################
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
    sudo usermod -aG docker $USER
    echo "Docker is now installed. A system restart is required for the changes to take effect."
    echo "Please restart your system and then re-run this script."
    exit 1
fi

#####################################################################################################################
# 2. select Client - $STARK-CLIENT
#####################################################################################################################
# select StarkNet Client
echo -n "select StarkNet client (1 - pathfinder, 2 - juno) > "
read selectclient
echo
if test "$selectclient" == "1"
then
    CLIENT="pathfinder"
    echo "export CLIENT=$CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$selectclient" == "2"
then
    CLIENT="juno"
    echo "export CLIENT=$CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

#####################################################################################################################
# 3. ENTER L1 URL, localhost or custom endpoint 
#####################################################################################################################
# SET L1 RPC PORT 
echo "StarkNet Node requires a connection to an L1 Endpoint- Ethereum Full Node"
echo "This can be hosted locally or an external service such as infura/alchemy"
echo "Is the rpc Port from L1 endpoint default (8545) or has it been changed (custom), NOTE: If using Sedge the port is (8547)" 
echo -n "enter port for L1 endpoint (1 - Enter Custom Port, 2 - Port is Default or using external service) > "
read select_stark_rpc_port
echo
if test "$select_stark_rpc_port" == "1"
then
    read -p "Enter custom L1 Port: " STARK_RPC_PORT
    echo "export STARK_RPC_PORT=$STARK_RPC_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_stark_rpc_port" == "2"
then
    STARK_RPC_PORT=$"8545"
    echo "export STARK_RPC_PORT=$STARK_RPC_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi 

# SET L1 URL
# echo "NOTE: currently pathfinder requires connection to a full archive node to sync"
echo "NOTE: is using juno client, then use the websocket endpoint ws"
echo -n "enter URL of L1 node or L1 node is hosted locally on the same device (1 - enter custom URL, 2 - L1 endpoint is hosted locally) > "
read select_stark_rpc_url
echo
if test "$select_stark_rpc_url" == "1"
then
    read -p "Enter L1 URL, the full URL including port if provided: " STARK_RPC_URL
    echo "export STARK_RPC_URL=$STARK_RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_stark_rpc_url" == "2"
then
    STARK_RPC_URL=$"http://localhost:$STARK_RPC_PORT"
    echo "export STARK_RPC_URL=$STARK_RPC_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

#####################################################################################################################
# CREATE DIRECTORIES
#####################################################################################################################
# create directories for starknet-node
mkdir -p $HOMEDIR/starknet-node/data
chmod -fR 700 $HOMEDIR/starknet-node/data
cd starknet-node

#####################################################################################################################
# CREATE docker-compose.yml
#####################################################################################################################
if [ "$CLIENT" == "pathfinder" ]; then
    cat > docker-compose.yml << EOF
version: '3.3'
services:
    starknet-node:
        image: 'eqlabs/pathfinder:v0.6.7'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        volumes:
            - ${HOMEDIR}/starknet-node/data:/usr/share/pathfinder/data
        ports:
            - '0.0.0.0:9545:9545'
            - '0.0.0.0:9546:9546'
        command:
            --data-directory "/usr/share/pathfinder/data"
            --ethereum.url "${STARK_RPC_URL}"
            --network "mainnet"
            --rpc.websocket
            --http-rpc "0.0.0.0:9545"
        environment:
            - RUST_LOG=info
            - PATHFINDER_RPC_WEBSOCKET=0.0.0.0:9546
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
EOF
elif [ "$CLIENT" == "juno" ]; then
    cat > docker-compose.yml << EOF
version: '3.3'
services:
    starknet-node:
        image: 'nethermindeth/juno:v0.4.0'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        volumes:
            - ${HOMEDIR}/starknet-node/data:/var/lib/juno
        ports:
            - '0.0.0.0:6060:6060'
            - '0.0.0.0:6061:6061'
        command:
            --db-path '/var/lib/juno'
            --eth-node '${STARK_RPC_URL}'
            --log-level 'info'
            --network 'mainnet'
            --http-port '6060' 
            --ws-port '6061'
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
EOF
else
    echo "Invalid CLIENT value. It should be either 'pathfinder' or 'juno'."
    exit 1
fi
#####################################################################################################################
# Start Stark Node
#####################################################################################################################
docker compose up -d
docker compose logs -f starknet-node
