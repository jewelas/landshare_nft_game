const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn2 = BigNumber.from("2");
const bn100 = BigNumber.from("100");
const bnDecimalPlaces = BigNumber.from("18");
const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource2 = bn2.mul(tokenDecimals);
const resource100 = bn100.mul(tokenDecimals);

describe("Game Contract Test: Token Harvest Limit", () => {

  let assetToken;
  let landToken;
  let setting;
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
    setting = getContracts().setting;
    house = getContracts().house;
    game = getContracts().game;
    stake = getContracts().stake;

    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(admin).activateHouse(tokenId);

    await landToken.transfer(game.address, resource100);

    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(admin.address, [200, 100, 100, 100, 100]);
  })
  it("Check token harvest limit", async () => {
    await setting.connect(admin).setHarvestLimit(2, 3);
    
    const stakeAmount = 100;
    await assetToken.approve(stake.address, stakeAmount);
    await stake.stake(stakeAmount, tokenId);

    await game.connect(admin).fortify(tokenId, 0);
    await game.connect(admin).fortify(tokenId, 1);
    await game.connect(admin).fortify(tokenId, 2);

    await increaseWorldTimeInSeconds(landshareConstants.interval.sixAndHalfDay, true);

    let harvestAmount = await house.connect(admin).getTokenReward(tokenId);
    expect(harvestAmount).to.be.equal(resource2).toString();
  })
  it("Check house dead time after it reached harvest limit", async () => {
    await setting.connect(admin).setHarvestLimit(2, 3);
    
    const stakeAmount = 100;
    await assetToken.approve(stake.address, stakeAmount);
    await stake.stake(stakeAmount, tokenId);

    await game.connect(admin).fortify(tokenId, 0);
    await game.connect(admin).fortify(tokenId, 1);
    await game.connect(admin).fortify(tokenId, 2);

    await increaseWorldTimeInSeconds(landshareConstants.interval.sixAndHalfDay, true);

    await game.harvest(tokenId, [true, false, false, false, false]);
    const houseData = await house.getOwnerAndStatus(tokenId)
    expect(houseData[2]).not.to.be.equal(0).toString();
  })
  it("Revert buy addon when house is dead", async () => {
    await setting.connect(admin).setHarvestLimit(2, 3);
    
    const stakeAmount = 100;
    await assetToken.approve(stake.address, stakeAmount);
    await stake.stake(stakeAmount, tokenId);

    await game.connect(admin).fortify(tokenId, 0);
    await game.connect(admin).fortify(tokenId, 1);
    await game.connect(admin).fortify(tokenId, 2);

    await increaseWorldTimeInSeconds(landshareConstants.interval.sixAndHalfDay, true);

    await game.harvest(tokenId, [true, false, false, false, false]);
    await expect(game.connect(admin).buyAddon(tokenId, 1)).to.be.revertedWith("House is dead");
  })
})
