#!/bin/bash

# Source the sub-script to execute checks and export variables
source provider_checks.sh

# Function to display status indicator
display_status() {
    local status=$1
    if [[ $status -eq 0 ]]; then
        echo -e "\e[32m✔\e[0m"  # Green tick
    else
        echo -e "\e[31m✘\e[0m"  # Red X
    fi
}

# Display the status table with bold text for headers
echo -e "\e[1mNODE CHECKS STATUS\e[0m"  # Bold
echo -e "\e[1mNGINX Setup:\e[0m $(display_status $nginx_status)"
echo -e "\e[1mNode Checks:\e[0m"  # Bold
echo -e "\tNode Type: $NODETYPE"
echo -e "\tNode Sync: $(display_status $node_sync_status)"
echo -e "\tNode Sub-Domain: $(display_status $subdomain_status)"
echo -e "\e[1mLava Node:\e[0m"  # Bold
echo -e "\tLava Node Connection: $(display_status $lava_node_connection_status)"
echo -e "\tLava Node Sync: $(display_status $lava_node_sync_status)"

# Cannot proceed until all checks are fine