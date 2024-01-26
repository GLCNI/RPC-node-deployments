#!/bin/bash

# Load environment variables
source "$HOME/.bashrc"

# Check the type of node installed
echo "You are running a $NODETYPE node."

####### NGINX CHECK #############

# Initialize nginx_status
nginx_status=0

# Check if NGINX is installed
nginx_version=$(nginx -v 2>&1)
if [[ $nginx_version == *"nginx/"* ]]; then
    echo "NGINX is installed correctly."
else
    echo "Something went wrong and NGINX does not appear to be installed."
    nginx_status=1  # Set status to failure
fi

####### NODE SYNC CHECK #############
# Function to check node synchronization status directly
check_sync_status() {
    local sync_status
    # Initialize node_sync_status
    node_sync_status=2  # Default to 2 error or unsupported node type

    case $NODETYPE in
        "osmosis"|"cosmos"|"juno")
            sync_status=$(curl -s http://127.0.0.1:26657/status | jq -r .result.sync_info.catching_up)
            ;;
        "arbitrum")
            sync_status=$(curl -s -X POST -H "Content-type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://127.0.0.1:8547 | jq -r .result)
            ;;
        "ethereum")
            sync_status=$(curl -s -X POST -H "Content-type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://127.0.0.1:8545 | jq -r .result)
            ;;
        *)
            echo "Unsupported node type: $NODETYPE"
            # node_sync_status remain 2 for error
            return
            ;;
    esac

    if [[ $sync_status == "false" ]]; then
        echo "Your $NODETYPE node is fully synced."
        node_sync_status=0  # Set to 0 for synced
    elif [[ $sync_status != "true" ]]; then
        echo "Your $NODETYPE node is still syncing. Please wait for the node to complete syncing before proceeding."
        node_sync_status=1  # Set to 1 for still syncing
    else
        echo "Something is wrong, you must check your $NODETYPE node is set up properly."
        # node_sync_status remains 2 for error mode
    fi
}

####### SUB-DOMAIN CHECK #############
# Confirm sub-domain
read -p "Your sub-domain is $NODETYPE.$DOMAIN_NAME. Is this correct? (y/n) " confirmation
if [[ $confirmation != "y" ]]; then
    echo "Exiting..."
    exit 1
fi

# Check sub-domain setup
check_subdomain_setup() {
    local subdomain_status_check
    # Initialize subdomain_status
    subdomain_status=1  # Default to 1 indicating error or unsupported node type

    if [[ $NODETYPE == "osmosis" || $NODETYPE == "cosmos" || $NODETYPE == "juno" ]]; then
        subdomain_status_check=$(curl -s https://$NODETYPE.$DOMAIN_NAME/status | jq -r .result.sync_info.catching_up)
    elif [[ $NODETYPE == "arbitrum" || $NODETYPE == "ethereum" ]]; then
        subdomain_status_check=$(curl -s -X POST -H "Content-type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' https://$NODETYPE.$DOMAIN_NAME | jq -r .result)
    else
        echo "Unsupported node type for sub-domain check: $NODETYPE"
        # subdomain_status remains 1 for error
        return
    fi

    if [[ $subdomain_status_check == "false" || $subdomain_status_check == "true" ]]; then
        echo "Your sub-domain is set up correctly."
        subdomain_status=0  # Set to 0 indicating set up correctly
    else
        echo "Something is wrong, check your sub-domain is set up properly."
        # subdomain_status remains 1 indicating error
    fi
}

# Run checks
check_sync_status
check_subdomain_setup

####### LAVA NODE CHECK #############
echo "This process requires a connection to a Lava full node."
echo "It is recommended to run this on a separate device, but you can also use a public endpoint."

# Initialize statuses
lava_node_connection_status=1  # initial Set to not connected
lava_node_sync_status=1        # initial Set to not synced

# Function to test connection and check syncing status
test_connection() {
    local node_url=$1
    local sync_status=$(curl -s $node_url/status | jq -r .result.sync_info.catching_up)

    # Check connection status
    if [ "$sync_status" == "null" ]; then
        echo "Something is wrong, and could not connect to the Lava node. Please ensure the device is set up properly and the IP/URL is correct."
        lava_node_connection_status=1  # Not connected
        return  # Exit function early
    else
        echo "Lava node is connected."
        lava_node_connection_status=0  # Connected
    fi

    # Check sync status
    if [[ $sync_status == "false" ]]; then
        echo "Lava node is connected and ready."
        lava_node_sync_status=0  # Synced
    elif [[ $sync_status == "true" ]]; then
        echo "Lava node is connected, but is still syncing. Please wait until it is fully synced."
        lava_node_sync_status=1  # Still syncing
    fi
}

# Prompt user for input
echo "1. Enter the IP address of your Lava node"
echo "2. Select a public endpoint or enter a custom URL"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        read -p "Enter the IP address of your Lava node: " lava_node_ip
        test_connection "http://$lava_node_ip:26657"
        ;;
    2)
        echo "Select an endpoint:"
        echo "1. example1.com"
        echo "2. example2.com"
        echo "3. Enter a custom URL"
        read -p "Enter your choice: " endpoint_choice

        case $endpoint_choice in
            1)
                test_connection "http://example1.com"
                ;;
            2)
                test_connection "http://example2.com"
                ;;
            3)
                read -p "Enter the custom URL: " custom_url
                test_connection $custom_url
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

export nginx_status
export node_sync_status
export subdomain_status
export lava_node_connection_status
export lava_node_sync_status