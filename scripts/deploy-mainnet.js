// scripts/deploy-fake-asset.js
const hre = require("hardhat");
const { BigNumber } = hre.ethers;

async function main () {
  const accounts = await hre.ethers.getSigners();
  const admin = accounts[0], alice = accounts[1];

  const landTokenAddress = "0x9D986A3f147212327Dd658F712d5264a73a1fdB0";
  const assetTokenAddress = "0xAC9611232704A38354858a8FBa4624a0b01987fB";
  
  // Deploy Setting contract
  const Setting = await hre.ethers.getContractFactory('Setting');
  console.log('Deploying Setting...');
  const setting = await Setting.deploy();
  await setting.deployed();
  console.log('Setting deployed to:', setting.address);

  // Deploy House contract
  const House = await hre.ethers.getContractFactory('HouseNFT');
  console.log('Deploying House NFT...');
  const house = await House.deploy('Land House', 'LSH', 10, setting.address);
  await house.deployed();
  console.log('House deployed to:', house.address);

  // Deploy Helper contract
  const Helper = await hre.ethers.getContractFactory('Helper');
  console.log('Deploying Helper...');
  const helper = await Helper.deploy(setting.address, house.address);
  await helper.deployed();
  console.log('Helper deployed to:', helper.address);

  // Deploy Validator contract
  const Validator = await hre.ethers.getContractFactory('Validator');
  console.log('Deploying Validator...');
  const validator = await Validator.deploy(
    landTokenAddress, // LandToken Address
    setting.address, // Setting Address
    house.address, // House Address
    helper.address // Helper Address
  );
  await validator.deployed();
  console.log('Validator deployed to:', validator.address);

  // Deploy Game contract
  const Game = await hre.ethers.getContractFactory('Game');
  console.log('Deploying Game...');
  const game = await Game.deploy(
    landTokenAddress, // LandToken Address
    setting.address, // Setting Address
    house.address, // House Address
    helper.address, // Helper Address
    validator.address // Validator Address
  );
  await game.deployed();
  console.log('Game deployed to:', game.address);

  // Deploy Stake contract
  const Stake = await hre.ethers.getContractFactory('Stake');
  console.log('Deploying Stake...');
  const stake = await Stake.deploy(
    house.address, // House Address
    assetTokenAddress, // AssetToken Address
    landTokenAddress // LandToken Address
  );
  await stake.deployed();
  console.log('Stake deployed to:', stake.address);

  
  // Set setting, house and stake contract addresses in game contract
  await game.setContractAddress(setting.address, house.address, helper.address, stake.address, validator.address);

  // Set stakeContractAddress and gameContractAddress in house.
  await house.setContractAddress(setting.address, helper.address, game.address, stake.address, assetTokenAddress);

  // Set Game contract address to validator contract
  await validator.setGameContractAddress(game.address);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
  