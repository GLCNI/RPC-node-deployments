# RPC-node-deployments
Library of deployment scripts and setup guides for Full nodes for various blockchains, these are minimum working configurations to get a ‘non validating’ ‘full / default’ node that stores the blockchain data and state. Intended to connect to externally for RPC provision.

run the script from the working directory or mounted drive you wish for the working folders and database to be stored

additional info found in /additional for information on other setup considerations such as installing Linux, mounting additional drives, sub-domains etc.

---------------

# Ethereum 

Full node for Ethereum network

Hardware requirements\ 
Minimum: Storage 2TB SSD / 8GB RAM / 4vCPU\
Recommended: Storage 4TB SSD / 16GB RAM / 4vCPU

### Node deployment tools: 

There are several tools to handle the Full setup, including installing dependencies, configuring clients with selection to get to a working state, allows configuration after setup. 

**Eth docker**
Docker automation for Ethereum nodes: [Github](https://github.com/eth-educators/eth-docker) [Docs](https://eth-docker.net/Usage/QuickStart)

**Installation**

Clone eth-docker 
```
cd ~ && git clone https://github.com/eth-educators/eth-docker.git && cd eth-docker
```

Install pre-requisites such as Docker

```
./ethd install
```

Configure eth-docker - have an Ethereum address handy where you want Execution Layer rewards to go
```
./ethd config
```

Start eth-docker
```
./ethd up
```

**Nethermind Sedge**

A one-click setup tool for PoS network/chain validators and nodes. [Github](https://github.com/NethermindEth/sedge) [Docs](https://docs.sedge.nethermind.io/docs/quickstart/install-guide)

**Installation**

Get sedge binary.
```
wget https://github.com/NethermindEth/sedge/releases/download/v<VERSION>/sedge-v<VERSION>-<OS>-<ARCH> -O sedge
#Make executable and move binary
chmod +x <binary>
cp <binary> /usr/local/bin/sedge
```

Run setup. 
```
sedge cli
```

Follow on screen prompts: Select network: Mainnet > Select Node Type: Full Node > Generation path: Default > Set up validator: No > Expose all ports: Yes 

---------------

# Ethereum Layer 2 Nodes

Requires connection to L1 endpoint, can be the Ethereum node setup from here 

## Arbitrum
Full node for Arbitrum network, Arbitrum one or Nova networks 

**Manual Setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/i4OnpBFIJUKA6z_pqN2gu2zst2MUaHOqrxSX4vCW9cM

**Install Script:** 

Download and make executable:
```
wget https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/arbitrum.sh && chmod a+x arbitrum.sh
```

Run Setup:
```
./arbitrum.sh
```

## StarkNet

### Pathfinder / Juno clients
Notes: Currently it looks like Pathfinder requires a connection to a full archival node, Juno works will default full node. 

**Manual Setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/lpKUpNTbRHgqFV28My563Hgohe0trtdqaAvpozILx1s

**Install Script:**

Download and make executable:
```
wget https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/starknet.sh && chmod a+x starknet.sh
```

Run Setup:
```
./starknet.sh
```

## Optimism 

PENDING

---------------

# Cosmos Nodes
Cosmos SDK based nodes, most are setup with cosmovisor to manage chain upgrades, setup as a system service. 

## Cosmos 
Cosmos network node (gaia) setup with cosmovisor to manage chain upgrades, setup as a system service. 

**Manual Setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/U4aUf8jjYvO7QKEjwyXC_ndpeSGCZWFnrR3q48-Yh7w

**Install Script:**

Download and make executable:
```
wget https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/cosmos.sh && chmod a+x cosmos.sh
```

Run Setup:
```
./cosmos.sh
```

## Osmosis 
Osmosis network node setup with cosmovisor to manage chain upgrades, setup as a system service. 

**Manual Setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/SSvumvvg9de_ls7EO9inJ6jLEMoC1OWQgimLJq9Cx4U

**Install Script:** 

Download and make executable:
```
wget https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/osmo.sh && chmod a+x osmo.sh
```

Run Setup:
```
./osmo.sh
```

## Juno 
Juno network node setup with cosmovisor to manage chain upgrades, setup as a system service. 

**Manual Setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/U4aUf8jjYvO7QKEjwyXC_ndpeSGCZWFnrR3q48-Yh7w

**Install Script:**

Download and make executable:
```
wget https://raw.githubusercontent.com/GLCNI/RPC-node-deployments/main/juno.sh && chmod a+x juno.sh
```

Run Setup:
```
./juno.sh
```

---------------

# Gnosischain 

**Manual setup:** https://mirror.xyz/0xf3bF9DDbA413825E5DdF92D15b09C2AbD8d190dd/Ty4_y4v6jfxBdevE-cIszzn-zaMFImg3AQsYY6sOhNE

**Install scripts:** 
**Nethermind Sedge**
See Ethereum - Node deployment tools > Nethermind Sedge
Follow on screen prompts: Select network: Gnosis > Select Node Type: Full Node > Generation path: Default > Set up validator: No > Expose all ports: Yes 

# Avalanche 

**Install script:**
Script made by ava-labs docs [here](https://docs.avax.network/nodes/build/set-up-node-with-installer) 
Creates a system service `avalanchego` to run and manage node

Download and run script
```
wget -nd -m https://raw.githubusercontent.com/ava-labs/avalanche-docs/master/scripts/avalanchego-installer.sh
chmod 755 avalanchego-installer.sh
./avalanchego-installer.sh
```

Interactive Prompts
	Select Dynamic IP `1` or Static IP `2`
	Select Expose Ports `private` or `public`: select `public` to expose the RPC port to all network interfaces.
	Select turn state sync on

Additional Options: 
To set custom db path, add flag to the run script command: `--db-dir /path/to/data`

