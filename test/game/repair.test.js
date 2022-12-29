const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn5 = BigNumber.from("5");
const bn10 = BigNumber.from("10");
const bnDecimalPlaces = BigNumber.from("18");
const tokenDecimals = bn10.pow(bnDecimalPlaces);
const percent5 = bn5.mul(tokenDecimals);
const percent10 = bn10.mul(tokenDecimals);

describe("Game Contract Test: Repair", () => {

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
    await game.addResourceByAdmin(alice.address, [100, 100, 100, 100, 100]);
  })
  it("reverts when user don't have ownership of houseNFT", async () => {
    await expect(game.connect(bob).repair(tokenId, percent5)).to.be.revertedWith("Repair: PD");
  })
  it("reverts when user repair over max durability", async () => {
    await expect(game.connect(alice).repair(tokenId, percent5)).to.be.revertedWith("Overflow maximium durability");
  })
  it("reverts when user repair below 10%", async () => {
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay);
    await expect(game.connect(alice).repair(tokenId, percent5)).to.be.revertedWith("Should repair at least 10%");
  })
  it("should emit 'Repair' event", async () => {
    //await house.setHouseForTest(tokenId);
    await increaseWorldTimeInSeconds(landshareConstants.interval.thirtyAndHalfDay);
    let receipt = await game.connect(alice).repair(tokenId, percent10);
    await expect(receipt).to.emit(game, 'Repair').withArgs(alice.address, tokenId, percent10);
  })
})
