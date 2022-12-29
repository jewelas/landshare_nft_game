const hre = require("hardhat");
const { BigNumber } = hre.ethers;

async function main () {
    const accounts = await hre.ethers.getSigners();
    const admin = accounts[0], alice = accounts[1];
  
    const houseNFTAddress = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e';
    const House = await ethers.getContractFactory('HouseNFT');
    const house = await House.attach(houseNFTAddress);

    // Set stakeContractAddress and gameContractAddress in house.
    await house.connect(admin).setContractAddress(setting.address, helper.address, game.address, stake.address, assetToken.address);

    // Set Game contract address to validator contract
    await validator.setGameContractAddress(game.address);

    await stake.setGameContractAddress(game.address); 

}