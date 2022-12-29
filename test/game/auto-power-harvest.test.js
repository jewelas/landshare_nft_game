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

describe("Game Contract Test: Auto Power Harvest", () => {

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

    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    
    windFarm = 0;
    lumberMill = 1;
    tokenId = 0;
    newTokenId = 2;
  })

  /**
    Test Story: Auto Power Harvest test
    1. mint NFT0, 1 day past
    2. Upgrade windfarm v2, 0.5 day past
    3. Upgrade Lumber v1, 1 day past
    4. Upgrade windfarm v3, 1 day past
    5. upgrade NFT0 windfarm v4
    6. Mint new NFT1,  2.5 day past
    7. upgrade NFT0 windfarm v5
  */
  it("check auto power harvest works correctly", async () => {
    await game.connect(alice).activateHouse(tokenId);
    await game.connect(alice).activateHouse(1);
    await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    // one day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay);

    // Upgrade prevNFT windfarm level v2
    await game.connect(alice).upgradeFacility(tokenId, windFarm); // update windfarm v2
    resource = await game.getResource(alice.address);
    const blockTime_02 = await ethers.provider.getBlock("latest");
    const cost = await setting.getFacilityUpgradeCost(windFarm, 2);

    const powerAmount_02 = resource200.sub(cost[0]);
    expect(resource[0].toString()).to.be.equal(powerAmount_02).toString();
    // 1.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay);
    
    // Upgrade Lumber Mill v1
    await game.connect(alice).upgradeFacility(tokenId, lumberMill); // Update Lumber Mill v1

    resource_03 = await game.getResource(alice.address);
    const blockTime_03 = await ethers.provider.getBlock("latest");
    const powerV1Amount = await setting.getResourceGenerationAmount(windFarm, 1); // WindFarm - v1 generation amount
    const powerGeneratedAmount_03 = await setting.getResourceGenerationAmount(windFarm, 2); // WindFarm - v2 generation amount
    const cost_03 = await setting.getFacilityUpgradeCost(lumberMill, 1); // Get cost for Lumber Mill v1
    let powerAmountGenerated_03 = powerGeneratedAmount_03.mul(BigNumber.from(blockTime_03.timestamp - blockTime_02.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    let powerV1AmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_03.timestamp - blockTime_02.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    const powerAmount_03 = powerAmount_02.add(powerAmountGenerated_03).add(powerV1AmountGenerated).sub(cost_03[0]);

    expect(resource_03[0].toString()).to.be.equal(powerAmount_03).toString();
    // 1 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay);

    // // Upgrade windfarm v3
    await game.connect(alice).upgradeFacility(tokenId, windFarm); // Update Windfarm v3

    resource_04 = await game.getResource(alice.address);
    const blockTime_04 = await ethers.provider.getBlock("latest");
    const powerGeneratedAmount_04 = await setting.getResourceGenerationAmount(windFarm, 2); // WindFarm - v2 generation amount
    const cost_04 = await setting.getFacilityUpgradeCost(windFarm, 3); // Get cost for windfarm v3
    let powerAmountGenerated_04 = powerGeneratedAmount_04.mul(BigNumber.from(blockTime_04.timestamp - blockTime_03.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    powerV1AmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_04.timestamp - blockTime_03.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    const powerAmount_04 = powerAmount_03.add(powerAmountGenerated_04).add(powerV1AmountGenerated).sub(cost_04[0]);
    
    expect(resource_04[0].toString()).to.be.equal(powerAmount_04).toString();
    // 1 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay);
    
    // Update Windfarm v4
    await game.connect(alice).upgradeFacility(tokenId, windFarm); 

    resource_05 = await game.getResource(alice.address);
    const blockTime_05 = await ethers.provider.getBlock("latest");
    const powerGeneratedAmount_05 = await setting.getResourceGenerationAmount(windFarm, 3); // WindFarm - v3 generation amount
    const cost_05 = await setting.getFacilityUpgradeCost(windFarm, 4); // Get cost for windfarm v4
    let powerAmountGenerated_05 = powerGeneratedAmount_05.mul(BigNumber.from(blockTime_05.timestamp - blockTime_04.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    powerV1AmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_05.timestamp - blockTime_04.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    const powerAmount_05 = powerAmount_04.add(powerAmountGenerated_05).add(powerV1AmountGenerated).sub(cost_05[0]);
    
    expect(resource_05[0].toString()).to.be.equal(powerAmount_05).toString();

    // Mint new NFT
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.connect(alice).activateHouse(newTokenId);
    const newNFTBlocktime = await ethers.provider.getBlock("latest");

    // 2.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay);

    // Update previous NFT windFarm v5
    await game.connect(alice).upgradeFacility(tokenId, windFarm); 

    // Calc power generated from previous NFT
    resource_06 = await game.getResource(alice.address);
    const blockTime_06 = await ethers.provider.getBlock("latest");
    const powerGeneratedAmount_06 = await setting.getResourceGenerationAmount(windFarm, 4); // WindFarm - v4 generation amount
    const cost_06 = await setting.getFacilityUpgradeCost(windFarm, 5); // Get cost for windfarm v5
    let powerAmountGenerated_06 = powerGeneratedAmount_06.mul(BigNumber.from(blockTime_06.timestamp - blockTime_05.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    powerV1AmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_06.timestamp - blockTime_05.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    
    // calc power generated from new NFT
    const powerGeneratedAmount_07 = await setting.getResourceGenerationAmount(windFarm, 1); // WindFarm - v1 generation amount
    let powerAmountGenerated_07 = powerGeneratedAmount_07.mul(BigNumber.from(blockTime_06.timestamp - newNFTBlocktime.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));

    // exiting power + generated power from prev NFT + generated power from new NFT - WindFarm v5 cost
    const powerAmount_06 = powerAmount_05.add(powerAmountGenerated_06).add(powerAmountGenerated_07).add(powerV1AmountGenerated).sub(cost_06[0]);

    expect(resource_06[0].toString()).to.be.equal(powerAmount_06).toString();
  });

})
