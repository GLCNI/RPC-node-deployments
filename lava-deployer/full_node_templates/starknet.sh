#!/bin/bash

# Store node type
NODETYPE=starknet
echo "export NODETYPE=$NODETYPE" >> "$HOME/.bashrc"

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
# 2. select Client
#####################################################################################################################
# select StarkNet Client
echo -n "select StarkNet client (1 - pathfinder, 2 - juno) > "
read selectclient
echo
if test "$selectclient" == "1"
then
    CLIENT="pathfinder"
    echo "export CLIENT=$CLIENT" >> $HOME/.bashrc
    source $HOME/.bashrc
fi
if test "$selectclient" == "2"
then
    CLIENT="juno"
    echo "export CLIENT=$CLIENT" >> $HOME/.bashrc
    source $HOME/.bashrc
fi

#####################################################################################################################
# 3. ENTER L1 URL, localhost or custom endpoint 
#####################################################################################################################
echo "StarkNet Node requires a connection to an L1 Endpoint- Ethereum Full Node"
echo "This can be hosted locally or an external service such as infura/alchemy"
sleep 5

# SET L1 URL
# echo "NOTE: currently pathfinder requires connection to a full archive node to sync"
echo "NOTE: if using juno client, then use the websocket endpoint ws or wss"
echo "Enter the full URL including port if required"
echo "example: if using localhost http://localhost:8545"
echo "example: for Infura url: wss://mainnet.infura.io/ws/v3/2376.....f"
read -p "Enter L1 URL, the full URL including port if provided: " L1_ENDPOINT_URL
echo "export L1_ENDPOINT_URL=$L1_ENDPOINT_URL" >> $HOME/.bashrc
source $HOME/.bashrc


#####################################################################################################################
# CREATE DIRECTORIES
#####################################################################################################################
# create directories for starknet-node
mkdir -p $HOMEDIR/starknet-node/data
sudo chown -R 1000:1000 $HOMEDIR/starknet-node/data
cd $HOMEDIR/starknet-node

#####################################################################################################################
# CREATE docker-compose.yml
#####################################################################################################################
if [ "$CLIENT" == "pathfinder" ]; then
    cat > docker-compose.yml << EOF
version: '3.3'
services:
    starknet-node:
        image: 'eqlabs/pathfinder:v0.10.3'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
#        network_mode: "host"
        volumes:
            - ${HOMEDIR}/starknet-node/data:/usr/share/pathfinder/data
        ports:
            - '0.0.0.0:9545:9545'
            - '0.0.0.0:9546:9546'
        command:
            --data-directory "/usr/share/pathfinder/data"
            --ethereum.url "${L1_ENDPOINT_URL}"
            --network "mainnet"
            --http-rpc "0.0.0.0:9545"
            --rpc.cors-domains "*"
            --rpc.root-version "v06"
            --rpc.websocket.enabled
            --rpc.enable "true"
            --sync.enable "true"
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
        image: 'nethermind/juno:v0.9.3'
        user: 1000:1000
        restart: always
        stop_grace_period: 30s
#        network_mode: "host"
        volumes:
            - ${HOMEDIR}/starknet-node/data/juno_mainnet:/var/lib/juno
        ports:
            - '0.0.0.0:6060:6060'
            - '0.0.0.0:6061:6061'
        command:
            --db-path '/var/lib/juno'
            --eth-node '${L1_ENDPOINT_URL}'
            --log-level 'info'
            --network 'mainnet'
            --http
            --http-port '6060'
            --http-host '0.0.0.0'
            --ws
            --ws-port '6061'
            --ws-host '0.0.0.0'
            --grpc
            --grpc-host '0.0.0.0'
            --grpc-port '6064'
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
# SNAPSHOT
#####################################################################################################################

# add option to use snapshot 
echo "NOTE: adding this feature for TESTING, may require additional configuration to make it work"
read -p "Do you want to use a snapshot? (yes/no): " use_snapshot
if [ "$use_snapshot" == "yes" ]; then
    if [ "$CLIENT" == "juno" ]; then
        # Snapshot for Juno client
        read -p "Enter Snapshot URL, find latest snapshot here: https://juno.nethermind.io/snapshots: " SNAPSHOT_URL
        echo "export SNAPSHOT_URL=$SNAPSHOT_URL" >> $HOME/.bashrc
        source $HOME/.bashrc
        cd
        # get snapshot
        wget -O juno_mainnet.tar $SNAPSHOT_URL
        # extract
        tar -xvf juno_mainnet.tar -C $HOMEDIR/starknet-node/data
    elif [ "$CLIENT" == "pathfinder" ]; then
        # Snapshot for Pathfinder client
        # NOTE THIS FEATURE IS UNTESTED 
        echo "Please visit `https://github.com/eqlabs/pathfinder#database-snapshots` to find the latest snapshot URL for your network and paste it here:"
        read -p "Enter Snapshot URL: " SNAPSHOT_URL

        # Install necessary tools if not installed
        if ! command -v rclone &> /dev/null; then
            echo "rclone could not be found, installing..."
            # download rclone root privileges no restart required
            curl https://rclone.org/install.sh | sudo bash
        fi

        if ! command -v zstd &> /dev/null; then
            echo "zstd could not be found, installing..."
            sudo apt-get install zstd -y
        fi

        # Configure rclone for pathfinder snapshots
        RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
        mkdir -p $(dirname "$RCLONE_CONFIG")

        echo "[pathfinder-snapshots]
        type = s3
        provider = Cloudflare
        env_auth = false
        access_key_id = 7635ce5752c94f802d97a28186e0c96d
        secret_access_key = 529f8db483aae4df4e2a781b9db0c8a3a7c75c82ff70787ba2620310791c7821
        endpoint = https://cbf011119e7864a873158d83f3304e27.r2.cloudflarestorage.com
        acl = private" > "$RCLONE_CONFIG"

        # Download the snapshot
        rclone copy -P "pathfinder-snapshots:${SNAPSHOT_URL##*/}" .

        # Verify SHA256 checksum (Optional step, requires published SHA2-256 checksum)
        # echo "Downloaded. Please verify the SHA2-256 checksum matches the published value."

        # Decompress the snapshot
        FILE_NAME="${SNAPSHOT_URL##*/}"
        zstd -T0 -d "$FILE_NAME" -o pathfinder_database.sqlite

        echo "Decompression complete. Database ready at pathfinder_database.sqlite"
    else
        echo "Invalid CLIENT value. It should be either 'pathfinder' or 'juno'."
        exit 1
    fi
else
    echo "Skipping snapshot setup."
fi

#####################################################################################################################
# Start StarkNet Node
#####################################################################################################################
cd $HOMEDIR/starknet-node
docker compose up -d
echo "Starting StarkNet Node with Docker"
sleep 30 

# confirm service is running
if [ $(docker compose ps -q starknet-node | wc -l) -gt 0 ] && [ "$(docker compose ps -q starknet-node | xargs docker inspect -f '{{.State.Running}}')" == "true" ]; then
    echo "Success"
cat <<'EOF'
  ____  _             _    _   _      _     _   _           _   
 / ___|| |_ __ _ _ __| | _| \ | | ___| |_  | \ | | ___   __| | ___
 \___ \| __/ _  | '__| |/ /  \| |/ _ \ __| |  \| |/ _ \ / _  |/ _ \
  ___) | || (_| | |  |   <| |\  |  __/ |_  | |\  | (_) | (_| |  __/
 |____/ \__\__,_|_|__|_|\_\_| \_|\___|\__| |_| \_|\___/ \__,_|\___|
        (_)___  |  _ \ _   _ _ __  _ __ (_)_ __   __ _             
        | / __| | |_) | | | | '_ \| '_ \| | '_ \ / _  |        
        | \__ \ |  _ <| |_| | | | | | | | | | | | (_| |         
        |_|___/ |_| \_\\__,_|_| |_|_| |_|_|_| |_|\__, |           
                                                 |___/
EOF 
    echo "Allow some time to catch up Sync, before proceeding to next steps"
    echo "To display logs from working directory $HOMEDIR/starknet-node & use 'docker compose logs -f starknet-node'"
else
    echo "Error: starknet-node may not be running correctly."
fi

# Press any key to continue
read -n 1 -s -r -p "Press any key to continue"
echo ""