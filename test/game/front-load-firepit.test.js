const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn2 = BigNumber.from("2");
const bn10 = BigNumber.from("10");
const bn200 = BigNumber.from("200");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource2 = bn2.mul(tokenDecimals);
const resource10 = bn10.mul(tokenDecimals);
const resource200 = bn200.mul(tokenDecimals);

describe("Game Contract Test: Frontload Firepit", () => {

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

  it('reverts when user upload more than 10 lumber', async () => {
    await expect(game.connect(alice).frontLoadFirepit(0, resource200)).to.be.revertedWith("Exceed Frontload Lumbers");
  });
  it('should have correct amount lumber after front load', async () => {
    await game.connect(alice).frontLoadFirepit(0, resource10);
    
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneDay, true);
    let resource = await game.getResource(alice.address);
    expect(resource200).to.be.equal(resource[1].add(resource10)).toString();
  })
  it('should have correct remain days after front load', async () => {
    await game.connect(alice).frontLoadFirepit(0, resource10);
    let remainDays = await house.getFirepitRemainDays(tokenId);
    expect(resource10).to.be.equal(remainDays).toString();
  })

})
