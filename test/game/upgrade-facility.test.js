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

describe("Game Contract Test: Upgrade Facility", () => {

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
    tokenId = 0;
    await game.connect(alice).activateHouse(tokenId);
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
  })

  it("should have correct initial levels", async () => {
    const level = await house.getFacilityLevel(0);
    expect(level).to.be.eql("1");
  })
  it("should have right level, cut resource by cost", async () => {
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded power station to level 2
    const level = await house.getFacilityLevel(0);
    expect(level).to.be.eql("2");

    const cost = await setting.getFacilityUpgradeCost(0, 2) // Cost for level 2 of power station
    const resource = await game.getResource(alice.address);
    expect((resource[2].add(cost[2])).toString()).to.be.equal((resource200).toString());
  })
  it("should emit 'UpgradeFacility' event", async () => {
    const receipt = await game.connect(alice).upgradeFacility(0, 0); // upgraded power station to level 2
    await expect(receipt).to.emit(game, 'UpgradeFacility').withArgs(alice.address, 0, 0, 2);
  })
  it("should return error with invalid level", async () => {
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded to level 2
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded to level 3
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded to level 4
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded to level 5
    await expect(game.connect(alice).upgradeFacility(0, 0)).to.be.revertedWith("Not allowed facility levels");
  })
  it("should update resource reward", async () => {
    await game.connect(alice).upgradeFacility(tokenId, 0); // upgraded to level 2
    const latestBlock = await ethers.provider.getBlock("latest");
    const data = await house.getHouse(0);
    const lastResourceRewardTime = data.lastResourceRewardTime[0];
    expect(latestBlock.timestamp).to.be.equal(lastResourceRewardTime);
  })
  it("should update right amount of resource reward", async () => {
    // Case: lumber 1 -> brick 1 -> lumber 2 -> brick 2
    let data = await house.getHouse(tokenId);
    let resource = data.resourceReward;
    expect(resource.toString()).to.be.equal([0, 0, 0, 0, 0].toString());

    await game.connect(alice).upgradeFacility(tokenId, 1); // Lumber level 1
    const blockToUpgradeLumberLevel1 = await ethers.provider.getBlock("latest");
    data = await house.getHouse(tokenId);
    resource = data.resourceReward; 
    expect(resource.toString()).to.be.equal([0, 0, 0, 0, 0].toString());

    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay);
    await game.connect(alice).upgradeFacility(tokenId, 2); // Brick level 1
    const blockToUpgradeBrickLevel1 = await ethers.provider.getBlock("latest");
    const lumberAmountGeneratedPerDay = await setting.getResourceGenerationAmount(1, 1); // Lumber - lvl 1
    let lumberAmountGenerated = lumberAmountGeneratedPerDay.mul(BigNumber.from(blockToUpgradeBrickLevel1.timestamp - blockToUpgradeLumberLevel1.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    data = await house.getHouse(tokenId);
    resource = data.resourceReward;
    expect(resource.toString()).to.be.equal([0, lumberAmountGenerated, 0, 0, 0].toString());

    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay);
    await game.connect(alice).upgradeFacility(tokenId, 1); // Lumber level 2
    const blockToUpgradeLumberLevel2 = await ethers.provider.getBlock("latest");
    const brickAmountGeneratedPerDay = await setting.getResourceGenerationAmount(2, 1); // Brick - lvl 1
    let brickAmountGenerated = brickAmountGeneratedPerDay.mul(BigNumber.from(blockToUpgradeLumberLevel2.timestamp - blockToUpgradeBrickLevel1.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    lumberAmountGenerated = lumberAmountGenerated.add(lumberAmountGeneratedPerDay.mul(BigNumber.from(blockToUpgradeLumberLevel2.timestamp - blockToUpgradeBrickLevel1.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay)));
    data = await house.getHouse(tokenId);
    resource = data.resourceReward;
    expect(resource.toString()).to.be.equal([0, lumberAmountGenerated, brickAmountGenerated, 0, 0].toString());

    await increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay);
    await game.connect(alice).upgradeFacility(tokenId, 2); // Brick level 2
    const blockToUpgradeBrickLevel2 = await ethers.provider.getBlock("latest");
    const lumber2AmountGeneratedPerDay = await setting.getResourceGenerationAmount(1, 2); // Lumber - lvl 2
    brickAmountGenerated = brickAmountGenerated.add(brickAmountGeneratedPerDay.mul(BigNumber.from(blockToUpgradeBrickLevel2.timestamp - blockToUpgradeLumberLevel2.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay)));
    lumberAmountGenerated = lumberAmountGenerated.add(lumber2AmountGeneratedPerDay.mul(BigNumber.from(blockToUpgradeBrickLevel2.timestamp - blockToUpgradeLumberLevel2.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay)));
    data = await house.getHouse(tokenId);
    resource = data.resourceReward;
    expect(resource.toString()).to.be.equal([0, lumberAmountGenerated, brickAmountGenerated, 0, 0].toString());
  })
  it("Upgrade facility gas fee", async () => {
    await game.connect(alice).upgradeFacility(tokenId, 1);
    await game.connect(alice).upgradeFacility(tokenId, 2);
    await game.connect(alice).upgradeFacility(tokenId, 3);
    await game.connect(alice).upgradeFacility(tokenId, 4);
    
  });

})
