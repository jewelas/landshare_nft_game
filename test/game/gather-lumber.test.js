const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn100 = BigNumber.from("100");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource100 = bn100.mul(tokenDecimals);

describe("Game Contract Test: Gather lumber with power", () => {

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
    await setting.connect(admin).setPowerLimit([300, 320, 330, 340, 350]);
    await game.addResourceByAdmin(alice.address, [300, 100, 100, 100, 100]);
  })

  it('reverts when user tries to gather invalid amount', async () => {
    await expect(game.connect(alice).gatherLumberWithPower(0)).to.be.revertedWith("Invaild amount to gather");
    await expect(game.connect(alice).gatherLumberWithPower(3)).to.be.revertedWith("Invaild amount to gather");
  });
  it('reverts when user tries to gather more than 2 lumber per day', async () => {
    await game.connect(alice).gatherLumberWithPower(1);
    await game.connect(alice).gatherLumberWithPower(1);
    await expect(game.connect(alice).gatherLumberWithPower(1)).to.be.revertedWith("Exceed Gathering limit");

    increaseWorldTimeInSeconds(landshareConstants.interval.halfDay, true);
    await expect(game.connect(alice).gatherLumberWithPower(1)).to.be.revertedWith("Exceed Gathering limit");

    increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    await game.connect(alice).gatherLumberWithPower(2);

    increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay, true);
    await game.connect(alice).gatherLumberWithPower(1);

    increaseWorldTimeInSeconds(landshareConstants.interval.halfDay, true);
    await expect(game.connect(alice).gatherLumberWithPower(2)).to.be.revertedWith("Exceed Gathering limit");

    await game.connect(alice).gatherLumberWithPower(1);
  })
  it("should gather correct amount of lumber to resource", async () => {
    await game.connect(alice).gatherLumberWithPower(2);
    let resource = await game.getResource(alice.address);
    let expectedLumber = resource100.add(tokenDecimals).add(tokenDecimals);
    expect(resource[1].toString()).to.be.equal(expectedLumber.toString());
    
    increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay, true);
    await game.connect(alice).gatherLumberWithPower(1);
    resource = await game.getResource(alice.address);
    expectedLumber = expectedLumber.add(tokenDecimals);
    expect(resource[1].toString()).to.be.equal(expectedLumber.toString());
  })
  it("should be able to gather up to 3 lumber after buying tree", async () => {
    const treeId = 3;
    await game.connect(alice).buyAddon(tokenId, treeId); // Buy Tree
    await game.connect(alice).gatherLumberWithPower(3);
    
    await expect(game.connect(alice).gatherLumberWithPower(1)).to.be.revertedWith("Exceed Gathering limit");
  })
})
