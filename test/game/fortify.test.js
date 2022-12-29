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

describe("Game Contract Test: Fortify", () => {

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
    await game.addResourceByAdmin(alice.address, [200, 100, 100, 100, 100]);
  })
  it("reverts when user don't have ownership of houseNFT", async () => {
    await expect(game.connect(bob).fortify(tokenId, 0)).to.be.revertedWith("Fortify: PD");
  })
  it("reverts when with invalid type of fortify", async () => {
    await expect(game.connect(alice).fortify(tokenId, 3)).to.be.revertedWith("Invalid fortification type");
  })
  it('should cost correct in number of fortification', async () => {
    // Brick
    await game.connect(alice).fortify(tokenId, 0);
    let userResource = await game.getResource(alice.address);
    let brickFCost = await setting.getFortifyCost(0);
    expect(userResource[2].toString()).to.be.equal(resource100.sub(brickFCost[2]).toString());
    // Concret
    await game.connect(alice).fortify(tokenId, 1);
    userResource = await game.getResource(alice.address);
    let concreteFCost = await setting.getFortifyCost(1);
    expect(userResource[3].toString()).to.be.equal(resource100.sub(concreteFCost[3]).toString());
    // Steel
    await game.connect(alice).fortify(tokenId, 2);
    userResource = await game.getResource(alice.address);
    let steelFCost = await setting.getFortifyCost(2);
    expect(userResource[4].toString()).to.be.equal(resource100.sub(steelFCost[4]).toString());
  })
  it("should emit 'Fortify' event", async () => {
    let receipt = await game.connect(alice).fortify(tokenId, 0);
    await expect(receipt).to.emit(game, 'Fortify').withArgs(alice.address, tokenId, 0);
    receipt = await game.connect(alice).fortify(tokenId, 1);
    await expect(receipt).to.emit(game, 'Fortify').withArgs(alice.address, tokenId, 1);
    receipt = await game.connect(alice).fortify(tokenId, 2);
    await expect(receipt).to.emit(game, 'Fortify').withArgs(alice.address, tokenId, 2);
  })
})
