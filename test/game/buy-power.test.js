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

describe("Game Contract Test: Buy Power with landtoken", () => {

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
    await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    adminTokenId = 1;
    windFarm = 0;
    await game.connect(admin).activateHouse(adminTokenId);
    blockTime_01 = await ethers.provider.getBlock("latest");
    await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
  })

  it('reverts when user buy power with no amount', async () => {
    await game.connect(alice).activateHouse(tokenId);
    await expect(game.connect(alice).buyPowerWithLandtoken(0)).to.be.revertedWith("No amount paid");
  });
  it('reverts when user buy power with exceed amount', async () => {
    const payAmount = resource200;
    await landToken.approve(game.address, payAmount);
    await expect(game.buyPowerWithLandtoken(payAmount)).to.be.revertedWith("Exceed the max power limit");
  });
  it('should have correct amount power', async () => {
    const payAmount = tokenDecimals;
    
    await landToken.approve(game.address, payAmount);
    await game.buyPowerWithLandtoken(payAmount);
    const blockTime_02 = await ethers.provider.getBlock("latest");
    const generatedPower = payAmount.mul(await setting.getPowerPerLandtoken());
    const resource = await game.getResource(admin.address);
    
    const powerV1Amount = await setting.getResourceGenerationAmount(windFarm, 1); // WindFarm - v1 generation amount
    let powerV1AmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_01.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
    const powerAmount_03 = powerV1AmountGenerated.add(BigNumber.from(generatedPower.toString()));
    
    expect((resource[0]).toString()).to.be.equal((powerAmount_03).toString());
  })
  it("should emit 'BuyPower' event", async () => {
    const payAmount = tokenDecimals;
    await landToken.approve(game.address, payAmount);
    const receipt = await game.buyPowerWithLandtoken(payAmount);
    const generatedPower = payAmount.mul(await setting.getPowerPerLandtoken());
    await expect(receipt).to.emit(game, 'BuyPower').withArgs(admin.address, payAmount, BigNumber.from(generatedPower.toString()));
  })

})
