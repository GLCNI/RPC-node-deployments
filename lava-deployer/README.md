# lava deployer

This is intended to be an interactive setup tool for `lava node` or `lava provider` and automate much of the deployment process.

**lava node:** setup a lava full node with or without cosmovisor, uses snapshot, option for wallet setup.

**lava provider:** full process to setup a lava provider node including running a selection of full nodes to provision rpc access with a lava provider process
interactive setup to guide all setup steps including:
- Full node setup options (most deployments use snapshot) 
- NGINX setup for sub-domain routing
- node checks for provider setup
- lava provider install and setup

**Supported nodes for Provider**
- Osmosis
- Cosmos
- StarkNet
- Arbitrum
- (more added soon)

**To Run:**
```
git clone https://github.com/GLCNI/RPC-node-deployments
cd RPC-node-deployments/lava-deployer
chmod +x run.sh
./run.sh
```
