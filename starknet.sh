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
echo "StarkNet Node requires a connection to an L1 Endpoint- Ethereum Full Node"
echo "This can be hosted locally or an external service such as infura/alchemy"
sleep 5

# SET CONNECTION INTERFACE
echo "select connection interface for L1 endpoiont"
echo "if using Juno client you must select ws, if using Pathfinder client you can use http or ws"
echo -n "enter connection interface for L1 endpoiont, if using Juno select 1 (1 - ws , 2 - http) > "
read select_interface
echo
if test "$select_interface" == "1"
then
    ENDPOINT_TYPE=$"ws"
    echo "export ENDPOINT_TYPE=$ENDPOINT_TYPE" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

if test "$select_interface" == "2"
then
    ENDPOINT_TYPE=$"http"
    echo "export ENDPOINT_TYPE=$ENDPOINT_TYPE" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi

# SET L1 PORT 
echo " NOTE: default http port is (8545), and default ws port is (8546), if using sedge please check this as it may be different"
echo "Is the PORT from L1 endpoint default or has it been changed (custom)?" 
echo -n "enter port for L1 endpoint (1 - Enter Custom Port, 2 - Port is Default or using external service) > "
read select_endpoint_port
echo
if test "$select_endpoint_port" == "1"
then
    read -p "Enter custom L1 Port: " ENDPOINT_PORT
    echo "export ENDPOINT_PORT=$ENDPOINT_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_endpoint_port" == "2"
then
    if [ "$ENDPOINT_TYPE" == "http" ]
    then
        ENDPOINT_PORT=$"8545"
    else
        ENDPOINT_PORT=$"8546"
    fi
    echo "export ENDPOINT_PORT=$ENDPOINT_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi 


# SET L1 URL
# echo "NOTE: currently pathfinder requires connection to a full archive node to sync"
echo "NOTE: is using juno client, then use the websocket endpoint ws"
echo -n "enter URL of L1 node or L1 node is hosted locally on the same device (1 - enter custom URL, 2 - L1 endpoint is hosted locally) > "
read select_endpoint_url
echo
if test "$select_endpoint_url" == "1"
then
    read -p "Enter L1 URL, the full URL including port if provided: " ENDPOINT_URL
    echo "export ENDPOINT_URL=$ENDPOINT_URL" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_endpoint_url" == "2"
then
    ENDPOINT_URL=$"$ENDPOINT_TYPE://localhost:$ENDPOINT_PORT"
    echo "export ENDPOINT_URL=$ENDPOINT_URL" >> $HOME/.bash_profile
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
        network_mode: "host"
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
        image: 'nethermind/juno:v0.4.1'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        network_mode: "host"
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
