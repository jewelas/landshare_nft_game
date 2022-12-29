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

describe("Game Contract Test: Fertilize Garden", () => {

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

  it('reverts when user tries without permission', async () => {
    await game.connect(alice).buyAddon(tokenId, 1);
    await game.connect(alice).buyAddon(tokenId, 2);
    await expect(game.connect(bob).fertilizeGarden(tokenId)).to.be.revertedWith("Fertilize Garden: PD");
  });
  it('reverts when user tries without active Garden upgrade', async () => {
    await expect(game.connect(alice).fertilizeGarden(tokenId)).to.be.revertedWith("Garden shoule be active");
  });
  it("should reduce fertilize cost from user's resource", async () => {
    await game.connect(alice).buyAddon(tokenId, 1);
    await game.connect(alice).buyAddon(tokenId, 2);
    await game.connect(alice).fertilizeGarden(tokenId);

    const addonCost1 = await setting.getBaseAddonCostById(1);
    const addonCost2 = await setting.getBaseAddonCostById(2);
    const cost = await setting.getFertilizeGardenCost();

    const resource = await game.getResource(alice.address);
    expect(resource100.toString()).to.be.equal(resource[2].add(BigNumber.from(addonCost1[2]).toString()).add(BigNumber.from(addonCost2[2]).toString()).add(BigNumber.from(cost[2].toString())).toString());
  })
})
