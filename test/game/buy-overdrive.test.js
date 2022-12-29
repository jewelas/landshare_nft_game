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

describe("Game Contract Test: Buy Overdrive", () => {

  let setting;
  let house;
  let game;
  let tokenId;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    setting = getContracts().setting;
    house = getContracts().house;
    game = getContracts().game;
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(alice).activateHouse(tokenId);
    blockTime_01 = await ethers.provider.getBlock("latest");
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
  })

  it('reverts when user buy overdrive with invalid facility type', async () => {
    await expect(game.connect(alice).buyResourceOverdrive(tokenId, 0)).to.be.revertedWith("Invalid facility type");
  });
  it('reverts when user buy overdrive without permission', async () => {
    await expect(game.connect(bob).buyResourceOverdrive(tokenId, 2)).to.be.revertedWith("Buy Overdrive: PD");
  });
  it('should have correct amount of power after overdrive', async () => {
    await game.connect(alice).buyResourceOverdrive(tokenId, 2);
    const resource = await game.getResource(alice.address);
    const cost = await setting.getOverdrivePowerCost();
    expect(resource200.toString()).to.be.equal((resource[0].add(cost)).toString());
  })
  it("should emit 'Buy Overdrive' event", async () => {
    const receipt = await game.connect(alice).buyResourceOverdrive(tokenId, 1);
    await expect(receipt).to.emit(game, 'BuyResourceOverdrive').withArgs(alice.address, tokenId, 1);
  })

})
