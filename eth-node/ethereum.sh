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

# Set the $ETH_HOMEDIR variable to the current working directory
export ETH_HOMEDIR="$(pwd)"
echo "export ETH_HOMEDIR=$ETH_HOMEDIR" >> "$HOME/.bash_profile"
source "$HOME/.bash_profile"

# INITIAL SETUP
# setup device and dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install curl git -y

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

#create directories 
mkdir -p $ETH_HOMEDIR/eth-node/el-client
mkdir $ETH_HOMEDIR/eth-node/cl-client
mkdir $ETH_HOMEDIR/eth-node/jwtsecret

#create JWT
cd $ETH_HOMEDIR/eth-node
openssl rand -hex 32 | tr -d "\n" > "$ETH_HOMEDIR/eth-node/jwtsecret/jwtsecret.hex"
cd

#DOCKER-COMPOSE-CLIENT-TEMPLATES
mkdir $ETH_HOMEDIR/eth-node/docker-compose-client-templates
curl https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/eth-node/docker-compose-client-templates/nethermind.yml \
  --output $ETH_HOMEDIR/eth-node/docker-compose-client-templates/nethermind.yml
curl https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/eth-node/docker-compose-client-templates/geth.yml \
  --output $ETH_HOMEDIR/eth-node/docker-compose-client-templates/geth.yml
curl https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/eth-node/docker-compose-client-templates/lighthouse.yml \
  --output $ETH_HOMEDIR/eth-node/docker-compose-client-templates/lighthouse.yml
curl https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/eth-node/docker-compose-client-templates/nimbus.yml \
  --output $ETH_HOMEDIR/eth-node/docker-compose-client-templates/nimbus.yml
# need goerli template for geth

# SET PORTS and VARIABLES
# set Ethereum netowrk $ETH_NETWORK
echo -n "Select ethereum network (1 - mainnet, 2 - goerli) > "
read select_ethereum_network
echo
if test "$select_ethereum_network" == "1"
then
    ETH_NETWORK=$"mainnet"
    echo "export ETH_NETWORK=$ETH_NETWORK" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
if test "$select_ethereum_network" == "2"
then
    ETH_NETWORK=$"goerli"
    echo "export ETH_NETWORK=$ETH_NETWORK" >> $HOME/.bash_profile
    source $HOME/.bash_profile
fi
# Set $ETH_NODE_RPC_PORT
echo "enter RPC port for ethereum full node, default is 8545"
read -p "Enter port for L1 URL: " ETH_NODE_RPC_PORT
    echo "export ETH_NODE_RPC_PORT=$ETH_NODE_RPC_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
# Set $EL_P2P_PORT
echo "enter execution P2P port for ethereum full node, default is 30303"
read -p "Enter port for L1 URL: " EL_P2P_PORT
    echo "export EL_P2P_PORT=$EL_P2P_PORT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
# Set $FEE_RECIPIENT address for consensus client, not needed for RPC but most clients error if not set
echo "enter fee recipient address (eth format), if none is set it may cuase error in consensus client"
read -p "Enter address: " FEE_RECIPIENT
    echo "export FEE_RECIPIENT=$FEE_RECIPIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile

#create docker-compose.yml
cd $ETH_HOMEDIR/eth-node
cat << EOF > docker-compose.yml
version: '3.3'
services:
EOF

#execution selection 
echo -n "Select execution client (1 - GETH, 2 - nethermind) > "
read select_execution_client
echo
if test "$select_execution_client" == "1"
then
    ETH_EL_CLIENT=$"geth"
    echo "export ETH_EL_CLIENT=$ETH_EL_CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    
    # Append the contents of geth.yml to docker-compose.yml
    cat $ETH_HOMEDIR/eth-node/docker-compose-client-templates/geth.yml >> $ETH_HOMEDIR/eth-node/docker-compose.yml
fi
if test "$select_execution_client" == "2"
then
    ETH_EL_CLIENT=$"nethermind"
    echo "export ETH_EL_CLIENT=$ETH_EL_CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    
    # Append the contents of nethermind.yml to docker-compose.yml
    cat $ETH_HOMEDIR/eth-node/docker-compose-client-templates/nethermind.yml >> $ETH_HOMEDIR/eth-node/docker-compose.yml
fi
# need condition for goerli for geth

#consensus selection
echo -n "Select consensus client (1 - lighthouse, 2 - nimbus) > "
read select_consensus_client
echo
if test "$select_consensus_client" == "1"
then
    ETH_CL_CLIENT=$"lighthouse"
    echo "export ETH_CL_CLIENT=$ETH_CL_CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    
    # add template to docker-compose.yml
    cat $ETH_HOMEDIR/eth-node/docker-compose-client-templates/lighthouse.yml >> $ETH_HOMEDIR/eth-node/docker-compose.yml
fi
if test "$select_consensus_client" == "2"
then
    ETH_CL_CLIENT=$"nimbus"
    echo "export ETH_CL_CLIENT=$ETH_CL_CLIENT" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    
    # add template to docker-compose.yml
    cat $ETH_HOMEDIR/eth-node/docker-compose-client-templates/nimbus.yml >> $ETH_HOMEDIR/eth-node/docker-compose.yml
fi

# complete docker-compose.yml
echo "
networks:
  net:
    external: true" >> $ETH_HOMEDIR/eth-node/docker-compose.yml

# configuration check 
echo "you are about to start an Ethereum full node on $ETH_NETWORK with $ETH_EL_CLIENT and $ETH_CL_CLIENT clients, RPC port is $ETH_NODE_RPC_PORT which will need exposed and port forwarded" 

# start node 
docker compose up -d

echo "Ethereum full node started with $ETH_EL_CLIENT and $ETH_CL_CLIENT clients, this will take a while to sync"
echo "to view client logs from inside the directory /eth-node"
echo "view $ETH_EL_CLIENT logs 'docker compose logs -f execution' "
echo "view $ETH_CL_CLIENT logs 'docker compose logs -f consensus' "
echo "to stop node 'docker compose down' configuration file is here: './eth-node/docker-compose.yml' "
