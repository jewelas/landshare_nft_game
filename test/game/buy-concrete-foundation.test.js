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

describe("Game Contract Test: Buy concrete foundation", () => {

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
    blockTime_01 = await ethers.provider.getBlock("latest");
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
  })

  it('reverts when user buy concrete foundation without permission', async () => {
    await expect(game.connect(bob).buyConcreteFoundation(tokenId)).to.be.revertedWith("Concrete Foundation: PD");
  });
  it('reverts when user already has concrete foundation', async () => {
    await game.connect(alice).buyConcreteFoundation(tokenId);
    await expect(game.connect(alice).buyConcreteFoundation(tokenId)).to.be.revertedWith("Concrete Foundation Exist");
  });
  it('should have correct amount lumber after front load', async () => {
    await game.connect(alice).buyConcreteFoundation(tokenId);
    const cost = await setting.connect(alice).getDurabilityDiscountCost();
    let resource = await game.getResource(alice.address);

    expect(resource200).to.be.equal(resource[4].add(cost[4])).toString();
  })
  it('should hosueNFT has concrete foundation upgrade after purchase', async () => {
    await game.connect(alice).buyConcreteFoundation(tokenId);
    const status = await house.getHasConcreteFoundation(tokenId);
    expect(status).to.be.equal(true).toString();
  })
  it("should emit 'Concrete Foundation' event", async () => {
    const receipt = await game.connect(alice).buyConcreteFoundation(tokenId);
    await expect(receipt).to.emit(game, 'ConcreteFoundation').withArgs(alice.address, tokenId);
  })

})
