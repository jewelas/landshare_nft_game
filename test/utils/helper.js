const { ethers } = require("hardhat");

const increaseWorldTimeInSeconds = async (seconds, mine = false) => {
  await ethers.provider.send('evm_increaseTime', [seconds]);
  if (mine) {
    await ethers.provider.send('evm_mine', []);
  }
}

module.exports = {
  increaseWorldTimeInSeconds
};
