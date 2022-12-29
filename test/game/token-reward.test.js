const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn200 = BigNumber.from("200");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource200 = bn200.mul(tokenDecimals);

describe("Game Contract Test: Token Reward", () => {

  let assetToken;
  let landToken;
  let setting;
  let house;
  let helper;
  let game;
  let stake;
  let tokenId;
  let stakeAmount;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    assetToken = getContracts().assetToken;
    landToken = getContracts().landToken;
    setting = getContracts().setting;
    house = getContracts().house;
    helper = getContracts().helper;
    game = getContracts().game;
    stake = getContracts().stake;
    
    stakeAmount = 200; // Deposit 200 ether
    tokenId = 0;
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.activateHouse(tokenId);
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(admin.address, [150, 200, 200, 200, 200]);
    await assetToken.approve(stake.address, stakeAmount);
    await stake.stake(stakeAmount, tokenId);
  })

  it("Check house token reward works correctly", async() => {

    const resource_01 = await game.getResource(admin.address);
    const blockTime_01 = await ethers.provider.getBlock("latest");
    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay, true); // 0.5 day past

    let houseData = await helper.getHouseDetails(tokenId);
    const durability_0 = houseData[0];
    const multiplier_0 = houseData[2];
    const expectedReward_0 = resource200.mul(multiplier_0).mul(durability_0).mul(BigNumber.from(landshareConstants.interval.halfDay)).div(BigNumber.from(landshareConstants.interval.oneYear)).div(tokenDecimals).div(tokenDecimals).div(100);
    const reward_0 = houseData[4];

    expect(reward_0.toString()).to.be.equal(expectedReward_0).toString();
  });
  
})
