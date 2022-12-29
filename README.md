# LandShare NFT Game

### Installation
```
npm install
```

### Run Local Network
```
npm run node
```

### Deployment

- Local network

```
npm run deploy-local
```

- Test network

```
npm run deploy-test
```

### Mint
- Local network

```
npm run mint-local
```

- Test network

```
npm run mint-test
```


### Test

- test on local
```
npm run test
```
- test on hardhat
```
npm run test:hardhat
```

### Verification
```
# Setting.sol
npx hardhat verify \
--network testnet
--contract "contracts/settings/Setting.sol:Setting" \
[DEPLOYED_SETTING_CONTRACT_ADDRESS]

# HouseNFT.sol
npx hardhat verify \
--network testnet \
--constructor-args scripts/house-args.js \
--contract "contracts/core/HouseNFT.sol:HouseNFT" \
[DEPLOYED_HOUSE_NFT_CONTRACT_ADDRESS]

# Helper.sol
npx hardhat verify \
--network testnet \
--constructor-args scripts/helper-args.js \
--contract "contracts/core/Helper.sol:Helper" \
[DEPLOYED_HELPER_CONTRACT_ADDRESS]

# Validator.sol
npx hardhat verify \
--network testnet \
--constructor-args scripts/validator-args.js \
--contract "contracts/game/Validator.sol:Validator" \
[DEPLOYED_VALIDATOR_CONTRACT_ADDRESS]

# Game.sol
npx hardhat verify \
--network testnet \
--constructor-args scripts/game-args.js \
--contract "contracts/game/Game.sol:Game" \
[DEPLOYED_GAME_CONTRACT_ADDRESS]

# Stake.sol
npx hardhat verify \
--network testnet \
--constructor-args scripts/stake-args.js \
--contract "contracts/core/Stake.sol:Stake" \
[DEPLOYED_STAKE_CONTRACT_ADDRESS]
```

### Other Hardhat Commands
```
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat help
npx hardhat check
```
