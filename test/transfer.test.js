const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("./utils/deploy");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

describe("Transfer NFT Test", () => {

  let assetToken;
  let landToken;
  let house;
  let game;
  let stake;
  let tokenId;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    assetToken = getContracts().assetToken;
    landToken = getContracts().landToken;
    house = getContracts().house;
    game = getContracts().game;
    stake = getContracts().stake;
    
    tokenId = 0;
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.activateHouse(tokenId);
  })

  describe("Transfer", () => {
    it('Revert when user transfer NFT without unstake', async () => {
      const stakeAmount = 10;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, tokenId);
        
      await house.connect(admin).approve(alice.address, tokenId);
      await expect(house.connect(admin).transferFrom(admin.address, alice.address, tokenId)).to.be.revertedWith("Please unstake asset tokens");
    })
  });
  it('Transfer Ownership from Admin to Alice', async () => {
    await house.connect(admin).approve(alice.address, tokenId);
    await house.connect(admin).transferFrom(admin.address, alice.address, tokenId);
    
    await expect(await house.ownerOf(tokenId)).to.be.equal((alice.address).toString());;
  })
});
