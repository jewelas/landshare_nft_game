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

describe("Game Contract Test: Hire handyman", () => {

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
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(admin).activateHouse(tokenId);
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
    await game.addResourceByAdmin(admin.address, [200, 200, 200, 200, 200]);
  })

  it('reverts when user hire handyman without permission', async () => {
    await expect(game.connect(bob).hireHandyman(tokenId)).to.be.revertedWith("HireHandyman: PD");
  });
  it('reverts when already used', async () => {
    await landToken.approve(game.address, resource200);
    await game.connect(admin).hireHandyman(tokenId);
    await increaseWorldTimeInSeconds(landshareConstants.interval.halfDay);
    await expect(game.connect(admin).hireHandyman(tokenId)).to.be.revertedWith("Already used");
  });
  it('should repaired max after used handyman', async () => {
    await landToken.approve(game.address, resource200);
    await increaseWorldTimeInSeconds(landshareConstants.interval.oneAndHalfDay);
    await game.connect(admin).hireHandyman(tokenId);
    const houseDetail = await helper.getHouseDetails(tokenId);
    expect(houseDetail[0]).to.be.equal(houseDetail[1]).toString();
  })
  it("should emit 'Repair By Handyman' event", async () => {
    await landToken.approve(game.address, resource200);
    const receipt = await game.connect(admin).hireHandyman(tokenId);
    await expect(receipt).to.emit(game, 'RepairByHandyman').withArgs(admin.address, tokenId);
  })

})
