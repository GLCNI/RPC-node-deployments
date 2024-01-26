#!/bin/bash

# Define paths to scripts
LAVA_NODE_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/full_node_templates/lava_node_setup.sh"
COSMOS_NODE_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/full_node_templates/cosmos.sh"
OSMOSIS_NODE_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/full_node_templates/osmosis.sh"
JUNO_NODE_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/full_node_templates/juno.sh"
ARBITRUM_NODE_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/full_node_templates/arbitrum.sh"
NGINX_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/nginx_setup.sh"
PROVIDER_SETUP_SCRIPT="$HOME/RPC-node-deployments/lava-deployer/provider_setup.sh"

# Function to display the main menu
main_menu() {
    OPTION=$(whiptail --title "Main Menu" --menu "Choose an option" 25 78 10 \
    "1" "Deploy a Lava Full Node" \
    "2" "Deploy a Full Node to setup with a provider" \
    "3" "Setup NGINX" \
    "4" "Start Provider process" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) deploy_lava_node ;;
        2) deploy_full_node ;;
        3) setup_nginx ;;
        4) start_provider_process ;;
    esac
}

# Function to deploy a Lava Full Node
deploy_lava_node() {
    echo "Deploying Lava Full Node..."
    bash "$LAVA_NODE_SETUP_SCRIPT"
}

# Function to deploy a Full Node
deploy_full_node() {
    NODE=$(whiptail --title "Select Node to Deploy" --menu "Choose a node" 25 78 10 \
    "1" "Cosmos" \
    "2" "Osmosis" \
    "3" "Juno" \
    "4" "Arbitrum" 3>&1 1>&2 2>&3)

    case $NODE in
        1) bash "$COSMOS_NODE_SETUP_SCRIPT" ;;
        2) bash "$OSMOSIS_NODE_SETUP_SCRIPT" ;;
        3) bash "$JUNO_NODE_SETUP_SCRIPT" ;;
        4) bash "$ARBITRUM_NODE_SETUP_SCRIPT" ;;
    esac

    # After deployment, offer to setup NGINX
    if (whiptail --title "Setup NGINX" --yesno "Do you want to setup NGINX now?" 8 78); then
        setup_nginx
    fi
}

# Function to setup NGINX
setup_nginx() {
    echo "Setting up NGINX..."
    bash "$NGINX_SETUP_SCRIPT"
}

# Function to start provider process
start_provider_process() {
    echo "Starting Provider process..."
    bash "$PROVIDER_SETUP_SCRIPT"
}

# Call the main menu function
main_menu
