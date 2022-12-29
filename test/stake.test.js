const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("./utils/deploy");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

describe("Stake Contract Test", () => {

  let assetToken;
  let landToken;
  let house;
  let game;
  let stake;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    assetToken = getContracts().assetToken;
    landToken = getContracts().landToken;
    house = getContracts().house;
    game = getContracts().game;
    stake = getContracts().stake;
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.activateHouse(0);
  })

  describe("Stake", () => {
    it('reverts when user stake house without ownerhsip of NFT', async () => {
      await expect(stake.connect(bob).stake(5, 0)).to.be.revertedWith("You do not own this NFT");
    });
    it('reverts when user try to stake with 0 amount', async () => {
      await expect(stake.stake(0, 0)).to.be.revertedWith("No Deposit");
    });
    it('should have correct stake value', async () => {
      const stakeAmount = 10;

      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
  
      expect((await stake.amountStaked(admin.address)).toString()).to.be.equal(stakeAmount.toString());
  
      expect((await house.connect(admin).getDepositedBalance(0)).toString()).to.be.equal(stakeAmount.toString());
  
      expect((await stake.hasStaked(admin.address)).toString()).to.be.equal((true).toString());
    })
  });

  describe("Unstake", () => {
    it('Revert when user unstake without ownership of NFT', async () => {
      const stakeAmount = 10;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
  
      await expect(stake.connect(bob).unstake(5, 0)).to.be.revertedWith("You do not own this NFT");
    })
    it('Revert when user unstake with 0 amount', async () => {
      const stakeAmount = 10;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
  
      await expect(stake.connect(admin).unstake(0, 0)).to.be.revertedWith("No Withdraw");
    })
    it('Revert when user unstake with more than balance', async () => {
      const stakeAmount = 10;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
  
      await expect(stake.connect(admin).unstake(15, 0)).to.be.revertedWith("Withdraw more than balance");
    })
    it('should have correct unstake value', async () => {
      let stakeAmount = 10;
      let unstakeAmount = 5;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
      await stake.unstake(unstakeAmount, 0);
      stakeAmount -= unstakeAmount;
  
      expect((await stake.amountStaked(admin.address)).toString()).to.be.equal(stakeAmount.toString());
      expect((await house.connect(admin).getDepositedBalance(0)).toString()).to.be.equal(stakeAmount.toString());
      expect((await stake.hasStaked(admin.address)).toString()).to.be.equal((true).toString());
    })
    it('should stake and unstake all should work', async () => {
      const stakeAmount = 10;
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
      await stake.unstake(stakeAmount, 0);
      await assetToken.approve(stake.address, stakeAmount);
      await stake.stake(stakeAmount, 0);
      await stake.unstake(stakeAmount, 0);
    })
  });

})
