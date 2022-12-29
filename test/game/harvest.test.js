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

describe("Game Contract Test: Harvest", () => {

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
    
    stakeAmount = 200;
    tokenId = 0;
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.activateHouse(tokenId);

    await landToken.transfer(game.address, resource200);

    await assetToken.approve(stake.address, 10000);
    await stake.stake(stakeAmount, tokenId);
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(admin.address, [150, 200, 200, 200, 200]);
  })

  it("reverts when user don't have ownership of houseNFT", async () => {
    await expect(game.connect(bob).harvest(tokenId, [true, true, false, false, false])).to.be.revertedWith("Harvest: PD");
  })
  it("Check harvest cost without harvester", async() => {
    await game.connect(admin).upgradeFacility(tokenId, 1); // Update Lumber Mill v1
    await game.connect(admin).upgradeFacility(tokenId, 2); // Update Brick Factory v1
    await game.connect(admin).upgradeFacility(tokenId, 3); // Update Concrete Plant v1

    const resource_01 = await game.getResource(admin.address);
    const blockTime_01 = await ethers.provider.getBlock("latest");
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true); // 1 day past
    
    // Harvest 
    const cost_01 = await helper.getHarvestCost(tokenId, [true, true, true, true, false]);
    await game.connect(admin).harvest(tokenId, [true, true, true, true, false]); // Harvest all resource
    const resource_02 = await game.getResource(admin.address);
    const blockTime_02 = await ethers.provider.getBlock("latest");

    const powerGeneratedAmount = await setting.getResourceGenerationAmount(tokenId, 1); // WindFarm - v1 generation amount
    let powerAmountGenerated = powerGeneratedAmount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_01.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    
    expect(resource_02[0].toString()).to.be.equal(resource_01[0].sub(cost_01).add(powerAmountGenerated)).toString();
  });
  it("Check harvest cost with harvester", async() => {
    await game.connect(admin).buyHarvester(tokenId); // Buy harvester
    await game.connect(admin).upgradeFacility(tokenId, 1); // Update Lumber Mill v1
    await game.connect(admin).upgradeFacility(tokenId, 2); // Update Brick Factory v1
    await game.connect(admin).upgradeFacility(tokenId, 3); // Update Concrete Plant v1

    const resource_01 = await game.getResource(admin.address);
    const blockTime_01 = await ethers.provider.getBlock("latest");
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true); // 1 day past
    
    // Harvest 
    const cost_01 = await helper.getHarvestCost(tokenId, [true, true, true, true, false]);
    await game.connect(admin).harvest(tokenId, [true, true, true, true, false]); // Harvest all resource
    const resource_02 = await game.getResource(admin.address);
    const blockTime_02 = await ethers.provider.getBlock("latest");

    const powerGeneratedAmount = await setting.getResourceGenerationAmount(0, 1); // WindFarm - v1 generation amount
    let powerAmountGenerated = powerGeneratedAmount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_01.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    
    expect(resource_02[0].toString()).to.be.equal(resource_01[0].sub(cost_01).add(powerAmountGenerated)).toString();
  });
  it("Check updated resource after harvest & harvested", async() => {
    await game.connect(admin).upgradeFacility(tokenId, 1); // Update Lumber Mill v1
    const blockTime_lumber = await ethers.provider.getBlock("latest");
    await game.connect(admin).upgradeFacility(tokenId, 2); // Update Brick Factory v1
    const blockTime_brick = await ethers.provider.getBlock("latest");
    await game.connect(admin).upgradeFacility(tokenId, 3); // Update Concrete Plant v1
    const blockTime_concrete = await ethers.provider.getBlock("latest");

    const resource_01 = await game.getResource(admin.address);
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true); // 1 day past
    
    // Harvest 
    await game.connect(admin).harvest(tokenId, [true, true, true, true, false]); // Harvest resources
    const blockTime_02 = await ethers.provider.getBlock("latest");
    const resource_02 = await game.getResource(admin.address);
    const lumberAmount = await setting.getResourceGenerationAmount(1, 1); // Lumber Mill - v1 generation amount
    const brickAmount = await setting.getResourceGenerationAmount(2, 1); // Brick Factory - v1 generation amount
    const concreteAmount = await setting.getResourceGenerationAmount(3, 1); // Concrete Factory - v1 generation amount
    let lumberAmountGenerated = lumberAmount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_lumber.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    let brickAmountGenerated = brickAmount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_brick.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    let concreteAmountGenerated = concreteAmount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_concrete.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));

    expect(resource_02[3].toString()).to.be.equal(resource_01[3].add(concreteAmountGenerated)).toString();
  });
  it("Reset after harvested", async() => {
    await game.connect(admin).upgradeFacility(tokenId, 1); // Update Lumber Mill v1
    await game.connect(admin).upgradeFacility(tokenId, 2); // Update Brick Factory v1
    await game.connect(admin).upgradeFacility(tokenId, 3); // Update Concrete Plant v1

    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true); // 1 day past
    
    // Harvest 
    await game.connect(admin).harvest(tokenId, [true, true, true, true, false]); // Harvest all resource
    let houseData = await helper.getHouseDetails(tokenId);
    const resourceReward = houseData[3];
    
    expect(resourceReward[1].toString()).to.be.equal("0").toString();
    expect(resourceReward[2].toString()).to.be.equal("0").toString();
    expect(resourceReward[3].toString()).to.be.equal("0").toString();
  });

})
