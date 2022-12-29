const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn50 = BigNumber.from("50");
const bn100 = BigNumber.from("100");
const bn200 = BigNumber.from("200");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const repair10 = bn10.mul(tokenDecimals);
const resource50 = bn50.mul(tokenDecimals);
const resource100 = bn100.mul(tokenDecimals);
const resource200 = bn200.mul(tokenDecimals);

describe("Game Contract Test: Get Repair Cost", () => {

  let assetToken;
  let landToken;
  let setting;
  let house;
  let helper;
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
    helper = getContracts().helper;
    game = getContracts().game;
    stake = getContracts().stake;

    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(alice).activateHouse(tokenId);
  })

  /**
    Test Story: Get repair cost
    1. 2.5 days past
    2. repair 10 %, calc cost
    3. buy 2 addons, 1 day past
    4. repair 10%, calc cost
    5. Buy toolshed, 1.5 day past
    6. repair 10%, calc cost
  */
  it("check repair cost works correctly", async () => {
    const blockTime_01 = await ethers.provider.getBlock("latest");
    await game.addResourceByAdmin(alice.address, [80, 100, 100, 100, 100]);

    // 1. 2.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true);

    // 2. Repair 10%, calc cost
    const repairCost_01 = await helper.getRepairCost(tokenId, repair10); // Get repair cost
    await game.connect(alice).repair(tokenId, repair10); // Repair 10%
    const resource_01 = await game.getResource(alice.address);
    const lumberAmount = resource100.sub(repairCost_01[1]);
    expect(resource_01[1].toString()).to.be.equal(lumberAmount).toString();

    // 3. Buy 2 addons, 1 day past
    await game.connect(alice).buyAddon(0, 5); // Buy Bathroom Remodel addon.
    await game.connect(alice).buyAddon(0, 6); // Buy Jacuzzi Tub addon.
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    const resource_02 = await game.getResource(alice.address);
    
    // 4. Repair 10%, calc cost
    const repairCost_02 = await helper.getRepairCost(tokenId, repair10); // Get repair cost
    await game.connect(alice).repair(tokenId, repair10); // Repair 10%
    const resource_03 = await game.getResource(alice.address); // Get current resource
    expect(resource_03[1].toString()).to.be.equal(resource_02[1].sub(repairCost_02[1])).toString();
    
    // 5. Buy toolshed, 1.5 day past
    await game.connect(alice).buyToolshed(tokenId, 1); // buy toolshed to reduce lumber 30%
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    const resource_04 = await game.getResource(alice.address); // Get current resource

    // 6. Repair 10%, calc cost
    const repairCost_03 = await helper.getRepairCost(tokenId, repair10); // Get repair cost
    await game.connect(alice).repair(tokenId, repair10); // Repair 10%
    const resource_05 = await game.getResource(alice.address); // Get current resource
    expect(resource_05[1].toString()).to.be.equal(resource_04[1].sub(repairCost_03[1])).toString();
  });

})
