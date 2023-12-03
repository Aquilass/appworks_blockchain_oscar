## Compound practice

### deploy with .env
change example.env to .env

### Deploy to local testnet
```git bash
forge script script/compound.s.sol:DeployCompound
```
### Deploy to Sepolia testnet
1. add env variables to .env
  MAINNET_RPC_URL
  SEPOLIA_RPC_URL
  PRIVATE_KEY
  ETHERSCAN_API_KEY
  ADMIN_ACCOUNT
2. run below command
3. ```git bash
   forge script script/compound.s.sol:DeployCompound --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvvv
   ```
