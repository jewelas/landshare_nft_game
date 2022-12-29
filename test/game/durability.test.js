const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn90 = BigNumber.from("90");
const bn100 = BigNumber.from("100");
const bn110 = BigNumber.from("110");
const bn130 = BigNumber.from("130");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource100 = bn100.mul(tokenDecimals);

describe("Game Contract Test: Durability", () => {

  let setting;
  let house;
  let helper;
  let game;
  let tokenId;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    setting = getContracts().setting;
    house = getContracts().house;
    game = getContracts().game;
    helper = getContracts().helper;
    
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(alice).activateHouse(tokenId);
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    reducedPercent = BigNumber.from(100 - await setting.getDurabilityReductionPercent(false));
  })

  it("should have correct inital value", async () => {
    let houseData = await helper.getHouseDetails(tokenId);
    const durabilityInStart = houseData[0];
    expect(durabilityInStart.toString()).to.be.equal(resource100.toString());
  });
  it("should have correct value after 1.5 day and 2.5 day", async () => {
    // 1.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay, true);
    let houseData = await helper.getHouseDetails(tokenId);
    let durability = houseData[0];
    let expectedDurability = resource100.mul(reducedPercent).div(bn100);
    expect(durability.toString()).to.be.equal(expectedDurability.toString());
    
    // another 1 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    expectedDurability = resource100.mul(reducedPercent).div(bn100).mul(reducedPercent).div(bn100);
    expect(durability.toString()).to.be.equal(expectedDurability.toString());
  });
  it("should have correct value after repairing at 1.5 days later and then 1 days later ", async () => {
    // 2.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay);
    // Repair 10%
    const percent10 = bn10.mul(tokenDecimals);
    await game.connect(alice).repair(tokenId, percent10);
    let houseData = await helper.getHouseDetails(tokenId);
    let durability = houseData[0];
    let expectedDurability = resource100.mul(reducedPercent).div(bn100).mul(reducedPercent).div(bn100).add(percent10);
    expect(durability.toString()).to.be.equal(expectedDurability.toString());
    
    // 1.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay, true);
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    expectedDurability = expectedDurability.mul(reducedPercent).div(bn100);
    expect(durability.toString()).to.be.equal(expectedDurability.toString());
  })
  it("should have correct value with max durability after fortifying 0.5, 1.5, 8 days later", async () => {
    // 0.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay);
    // Fortify brick 10% (with repair 10%)
    await game.connect(alice).fortify(tokenId, 0);

    // 0.5 day past
    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay, true);

    let houseData = await helper.getHouseDetails(tokenId);
    let durability = houseData[0];
    let maxDurability = houseData[1];
    const percent110 = bn110.mul(tokenDecimals);
    expect(durability.toString()).to.be.equal(percent110.toString());
    expect(maxDurability.toString()).to.be.equal(percent110.toString());

    // another 1 day past (1.5 days)
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    maxDurability = houseData[1];
    expect(maxDurability.toString()).to.be.equal(percent110.toString());
    expect(durability.toString()).to.be.equal(percent110.mul(bn90).div(bn100).toString());

    // another 6.5 days past (8 days)
    await increaseWorldTimeInSeconds(landshareConstants.interval.sixAndHalfDay, true);
    houseData = await helper.getHouseDetails(tokenId);
    maxDurability = houseData[1];
    expect(maxDurability.toString()).to.be.equal(resource100.toString());
  })
  it("should have correct values around end of fortification", async () => {
    // Fortify 10% (with repair 10%)
    await game.connect(alice).fortify(tokenId, 0);
    // Fortify 10% (with repair 10%)
    await game.connect(alice).fortify(tokenId, 1);
    // Fortify 10% (with repair 10%)
    await game.connect(alice).fortify(tokenId, 2);

    let houseData = await helper.getHouseDetails(tokenId);
    let initialDurability = houseData[0];
    let maxDurability = houseData[1];
    const percent130 = bn130.mul(tokenDecimals);
    expect(initialDurability.toString()).to.be.equal(percent130.toString());
    expect(maxDurability.toString()).to.be.equal(percent130.toString());

    // 6.5 days past
    await increaseWorldTimeInSeconds(landshareConstants.interval.sixAndHalfDay, true);
    for (i = 0; i < 6; i++)
    initialDurability = initialDurability.mul(bn90).div(bn100);
    
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    maxDurability = houseData[1];
    expect((durability).toString()).to.be.equal(initialDurability.toString());
    expect((maxDurability).toString()).to.be.equal(percent130.toString());
    
    // Repair to max durability (130%)
    await game.connect(alice).repair(tokenId, percent130.sub(initialDurability));
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    expect((durability).toString()).to.be.equal(percent130.toString());

    // // another 1 day past (7.5 days later)
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    
    houseData = await helper.getHouseDetails(tokenId);
    durability = houseData[0];
    maxDurability = houseData[1];
    expect((durability).toString()).to.be.equal(resource100.toString());
    expect((maxDurability).toString()).to.be.equal(resource100.toString());
  })
})
