const { ethers } = require("hardhat");

let contracts = {};

const deployContracts = async () => {
  // Deploy fake asset token
  const AssetToken = await hre.ethers.getContractFactory('LS81712NFToken');
  const assetToken = await AssetToken.connect(admin).deploy();
  await assetToken.deployed();
  // console.log('AssetToken deployed to:', assetToken.address);

  // Deploy fake land token
  const LandToken = await ethers.getContractFactory('FakeLandToken');
  const landToken = await LandToken.deploy();
  await landToken.deployed();
  // console.log('LandToken deployed to:', landToken.address);

  // Deploy Setting contract
  const Setting = await ethers.getContractFactory('Setting');
  const setting = await Setting.deploy();
  await setting.deployed();
  // console.log('Setting deployed to:', setting.address);

  // Deploy House contract
  const House = await ethers.getContractFactory('HouseNFT');
  const house = await House.deploy('Land House', 'LSH', 10, setting.address);
  await house.deployed();
  // console.log('House deployed to:', house.address);

  const Helper = await hre.ethers.getContractFactory('Helper');
  //console.log('Deploying Helper...');
  const helper = await Helper.deploy(setting.address, house.address);
  await helper.deployed();
  //console.log('Helper deployed to:', helper.address);

  const Validator = await hre.ethers.getContractFactory('Validator');
  //console.log('Deploying Validator...');
  const validator = await Validator.deploy(landToken.address, setting.address, house.address, helper.address);
  await validator.deployed();
  //console.log('Validator deployed to:', validator.address);

  // Deploy Game contract
  const Game = await hre.ethers.getContractFactory('Game');
  // //console.log('Deploying Game...');
  const game = await Game.deploy(
    landToken.address, // LandToken Address
    setting.address, // Setting Address
    house.address, // House Address
    helper.address, // Helper Address
    validator.address // Validator Address
  );
  await game.deployed();
  // //console.log('Game deployed to:', game.address);

  // Deploy Stake contract
  const Stake = await ethers.getContractFactory('Stake');
  const stake = await Stake.deploy(
    house.address,
    assetToken.address,
    landToken.address
  );
  await stake.deployed();
  // console.log('Stake deployed to:', stake.address);

  
  // Set setting, house and stake contract addresses in game contract
  await game.setContractAddress(setting.address, house.address, helper.address, stake.address, validator.address);

  // Set stakeContractAddress and gameContractAddress in house.
  await house.setContractAddress(setting.address, helper.address, game.address, stake.address, assetToken.address);

  // Set gameContractAddress in validator
  await validator.setGameContractAddress(game.address);

  // Add alice to whitelist
  await assetToken.addWhitelister(admin.address);
  await assetToken.connect(admin).addAddressToWhitelist(alice.address);

  contracts = {
    assetToken,
    landToken,
    setting,
    house,
    helper,
    validator,
    game,
    stake
  };
}

const getContracts = () => contracts;

module.exports = { deployContracts, getContracts }
