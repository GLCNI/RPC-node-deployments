#!/bin/bash

# Store node type
NODETYPE=arbitrum
echo "export NODETYPE=$NODETYPE" >> "$HOME/.bashrc"

#####################################################################################################################
# 1. Install dependancies
#####################################################################################################################
# Set the $HOMEDIR variable to the current working directory
export ARB_HOMEDIR="$(pwd)"

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
# 2. select Arbitrum Network
#####################################################################################################################
# ABITRUM CHAIN SELECTION
# Run a full node on Arbitrum One or Arbitrum Nova chain 
echo -n "Select Arbitrum Network (1 - Arbitrum One, 2 - Arbitrum Nova, 3 - Nitro Sepolia Testnet) > "
read select_arb_chain
echo
if test "$select_arb_chain" == "1"
then
    ARB_CHAIN=$"42161"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bashrc
    source $HOME/.bashrc
fi
if test "$select_arb_chain" == "2"
then
    ARB_CHAIN=$"42170"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bashrc
    source $HOME/.bashrc
fi
if test "$select_arb_chain" == "3"
then
    ARB_CHAIN=$"421614"
    echo "export ARB_CHAIN=$ARB_CHAIN" >> $HOME/.bashrc
    source $HOME/.bashrc
fi

#set genesis db snapshot
# Arbitrum One
if [ "$ARB_CHAIN" == "42161" ]
then
    ARB_INIT_URL="https://snapshot.arbitrum.foundation/arb1/nitro-pruned.tar"
# Arbitrum Nova
elif [ "$ARB_CHAIN" == "42170" ]
then
    ARB_INIT_URL="https://snapshot.arbitrum.foundation/nova/nitro-pruned.tar"
# Testnet Sepolia
elif [ "$ARB_CHAIN" == "421614" ]
then
    ARB_INIT_URL="https://snapshot.arbitrum.foundation/sepolia/nitro-pruned.tar"
fi
echo "export ARB_INIT_URL=$ARB_INIT_URL" >> $HOME/.bashrc
source $HOME/.bashrc

#####################################################################################################################
# 3. ENTER L1 URL, localhost or custom endpoint 
#####################################################################################################################
echo "Arbitrum Node requires a connection to an L1 Endpoint- Ethereum Full Node"
echo "This can be hosted locally or an external service such as infura/alchemy"
sleep 5

# SET L1 URL
echo "Enter the full URL including port if required"
echo "example: if using localhost http://localhost:8545"
echo "example: for Infura url: https://mainnet.infura.io/v3/23...ad"
read -p "Enter L1 URL, the full URL including port if provided: " L1_ENDPOINT_URL
echo "export L1_ENDPOINT_URL=$L1_ENDPOINT_URL" >> $HOME/.bashrc
source $HOME/.bashrc


#####################################################################################################################
# CREATE DIRECTORIES
#####################################################################################################################
# create directories for arbitrum-node
mkdir -p $ARB_HOMEDIR/arbitrum-node/data
chmod -fR 777 $ARB_HOMEDIR/arbitrum-node/data
cd $ARB_HOMEDIR/arbitrum-node

#####################################################################################################################
# CREATE docker-compose.yml
#####################################################################################################################
# create docker-compose.yml file 
cat << EOF > docker-compose.yml
version: '3.3'
services:
    arbitrum-node:
        image: 'offchainlabs/nitro-node:v2.2.2-8f33fea'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
        volumes:
            - '$ARB_HOMEDIR/arbitrum-node/data/:/home/user/.arbitrum'
            - /etc/timezone:/etc/timezone:ro
            - /etc/localtime:/etc/localtime:ro
        ports:
            - '0.0.0.0:8547:8547'
            - '0.0.0.0:8548:8548'
        command:
        - --init.url=$ARB_INIT_URL
        - --parent-chain.connection.url=$L1_ENDPOINT_URL
        - --chain.id=$ARB_CHAIN
        - --http.addr=0.0.0.0
        - --http.api=net,web3,eth,arb
        - --http.corsdomain=*
        - --http.port=8547
        - --http.rpcprefix=/
        - --http.vhosts=*
        - --ws.addr=0.0.0.0
        - --ws.api=net,web3,eth,arb
        - --ws.expose-all
        - --ws.origins=*
        - --ws.port=8548
        - --ws.rpcprefix=/
        logging:
          driver: json-file
          options:
            max-size: 10m
            max-file: "10"
EOF

#####################################################################################################################
# Start Arbitrum Node
#####################################################################################################################
cd $ARB_HOMEDIR/arbitrum-node
docker compose up -d
echo "Starting Arbitrum Node with Docker"
sleep 30

# confirm service is running
if [ $(docker compose ps -q arbitrum-node | wc -l) -gt 0 ] && [ "$(docker compose ps -q arbitrum-node | xargs docker inspect -f '{{.State.Running}}')" == "true" ]; then
    echo "Success"
cat <<'EOF'
           _____  ____ _____ _______ _____  _    _ __  __         _   _  ____  _____  ______
     /\   |  __ \|  _ \_   _|__   __|  __ \| |  | |  \/  |       | \ | |/ __ \|  __ \|  ____|
    /  \  | |__) | |_) || |    | |  | |__) | |  | | \  / |       |  \| | |  | | |  | | |__  
   / /\ \ |  _  /|  _ < | |    | |  |  _  /| |  | | |\/| |       | .   | |  | | |  | |  __|
  / ____ \| | \ \| |_) || |_   | |  | | \ \| |__| | |  | |       | |\  | |__| | |__| | |____
 /_/    \_\_|  \_\____/_____| _|_|_ |_|  \_\\____/|_| _|_|___ _  |_| \_|\____/|_____/|______|
              |_   _|/ ____| |  __ \| |  | | \ | | \ | |_   _| \ | |/ ____|
                | | | (___   | |__) | |  | |  \| |  \| | | | |  \| | |
                | |  \___ \  |  _  /| |  | | .   | .   | | | | .   | | |_ |
               _| |_ ____) | | | \ \| |__| | |\  | |\  |_| |_| |\  | |__| |
              |_____|_____/  |_|  \_\\____/|_| \_|_| \_|_____|_| \_|\_____|
EOF
    echo "Allow some time to catch up Sync, before proceeding to next steps"
    echo "To display logs from working directory $HOME/arbitrum-node & use 'docker compose logs -f arbitrum-node'"
else
    echo "Error: arbitrum-node may not be running correctly."
fi

# Press any key to continue
read -n 1 -s -r -p "Press any key to continue"
echo ""