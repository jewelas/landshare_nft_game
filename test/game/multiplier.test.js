const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("../utils/deploy");
const { increaseWorldTimeInSeconds } = require("../utils/helper");
const landshareConstants = require("../utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);

const bn10 = BigNumber.from("10");
const bn50 = BigNumber.from("50");
const bn100 = BigNumber.from("100");
const bn200 = BigNumber.from("200");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource50 = bn50.mul(tokenDecimals);
const resource100 = bn100.mul(tokenDecimals);
const resource200 = bn200.mul(tokenDecimals);

describe("Game Contract Test: Check multiplier", () => {

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

    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    tokenId = 0;
    await game.connect(alice).activateHouse(tokenId);
    gardenId = 2;
    landscapingId = 1;
    await setting.connect(admin).setPowerLimit([300, 320, 330, 340, 350]);
  })

  /**
    Test Story: Calculate Multiplier
    1. Check multiplier
    2. Buy addon => Bathroom Remodel (without fortification)
    3. Check multiplier
    4. Buy addon => Jacuzzi Tub (without fortification)
    5. Check multiplier
    6. Fortify with bricks
    7. Buy addons (with fortification)
    8. Check multiplier, 2.5 day past
    9. Fortify with concrete
    10. Check multiplier, 2.5 day past
    11. Fortify with steel, buy Steel siding & Finished basement
    12. Check multiplier 2.5 day past
    13. Check multiplier
  */
  it("check calculate multiplier works correctly", async () => {
    const blockTime_01 = await ethers.provider.getBlock("latest");
    await game.addResourceByAdmin(alice.address, [280, 100, 100, 100, 100]);
    // 1. Check multiplier without addons
    let houseData = await helper.getHouseDetails(tokenId);
    const multiplier_01 = houseData[2];
    const calculatedMul = await setting.getStandardMultiplier();
    expect(multiplier_01.toString()).to.be.equal(calculatedMul).toString();

    // 2. Buy addon => Bathroom Remodel (without fortification)
    await game.connect(alice).buyAddon(0, 5); // Alice buy Bathroom Remodel addon.

    // 3. check Multiplier
    const baseAddonMultiplier = await setting.getBaseAddonMultiplier();
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_02 = houseData[2]; // get current multiplier
    const addon_01_mul = baseAddonMultiplier[5];
    expect(multiplier_02.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).div(100)).toString();

    // 4. Buy addon => Jacuzzi Tub (without fortification)
    await game.connect(alice).buyAddon(0, 6); // Alice buy Jacuzzi Tub addon.

    // 5. check Multiplier
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_03 = houseData[2]; // get current multiplier
    const addon_02_mul = baseAddonMultiplier[6];
    expect(multiplier_03.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).div(100).div(100)).toString();

    // 6. Fortify brick
    await game.connect(alice).fortify(tokenId, 0);

    // 7. Buy addon => Root cellar
    await game.connect(alice).buyAddon(0, 9); // Alice buy Root cellar

    // 8. Check multiplier, 2.5 day past
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_04 = houseData[2]; // get current multiplier

    const addon_03_mul = baseAddonMultiplier[9];
    expect(multiplier_04.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_03_mul).div(100).div(100).div(100)).toString();
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true); // 2.5 day past

    // 9. Fortify with concrete, Buy addon => Steel Sliding
    await game.connect(alice).fortify(tokenId, 1);
    await game.connect(alice).buyAddon(0, 7);

    // 10. Check multiplier, 2.5 day past
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_05 = houseData[2]; // get current multiplier
    const addon_04_mul = baseAddonMultiplier[7];
    expect(multiplier_05.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_03_mul).mul(addon_04_mul).div(100).div(100).div(100).div(100)).toString();
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true); // 2.5 day past

    // 11. Fortify with Steel, Buy addon => Kitchen Model, Finished Basement
    await game.connect(alice).fortify(tokenId, 2);
    await game.connect(alice).buyAddon(0, 4);
    await game.connect(alice).buyAddon(0, 10);

    // 12. Check multiplier, 2.5 day past => Max_durability must be 130
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_06 = houseData[2]; // get current multiplier
    const addon_05_mul = baseAddonMultiplier[4];
    const addon_06_mul = baseAddonMultiplier[10];
    expect(multiplier_06.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_03_mul).mul(addon_04_mul).mul(addon_05_mul).mul(addon_06_mul).div(100).div(100).div(100).div(100).div(100).div(100)).toString();
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true); // 2.5 day past

    // 13. Check multiplier, 2.5 day past => Max_durability must be 120
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_07 = houseData[2]; // get current multiplier
    expect(multiplier_07.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_04_mul).mul(addon_05_mul).mul(addon_06_mul).div(100).div(100).div(100).div(100).div(100)).toString();
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true); // 2.5 day past

    // 14. Check multiplier, 2.5 day past => Max_durability must be 110
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_08 = houseData[2]; // get current multiplier
    expect(multiplier_08.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_05_mul).mul(addon_06_mul).div(100).div(100).div(100).div(100)).toString();
    await increaseWorldTimeInSeconds(landshareConstants.interval.twoAndHalfDay, true); // 2.5 day past

    // 15. Check multiplier, Max durability must be 100
    houseData = await helper.getHouseDetails(tokenId);
    const multiplier_09 = houseData[2]; // get current multiplier
    expect(multiplier_09.toString()).to.be.equal(calculatedMul.mul(addon_01_mul).mul(addon_02_mul).mul(addon_05_mul).div(100).div(100).div(100)).toString();
  });

  it("garden should be expired after 7 days", async () => {
    await game.addResourceByAdmin(alice.address, [100, 100, 100, 100, 100]);

    let multiplier = (await helper.getHouseDetails(tokenId))[2];
    let expectedMul = await setting.getStandardMultiplier();
    expect(multiplier.toString()).to.be.equal(expectedMul.toString());
    await game.connect(alice).buyAddon(tokenId, landscapingId);
    await game.connect(alice).buyAddon(tokenId, gardenId);

    multiplier = (await helper.getHouseDetails(tokenId))[2];
    const baseAddonMultiplier = await setting.getBaseAddonMultiplier();
    const landscapingMul = baseAddonMultiplier[landscapingId];
    const gardenMul = baseAddonMultiplier[gardenId];
    expectedMul = expectedMul.mul(landscapingMul).mul(gardenMul).div(100).div(100);
    expect(multiplier.toString()).to.be.equal(expectedMul.toString());

    await increaseWorldTimeInSeconds(landshareConstants.interval.sevenAndHalfDay, true); 

    multiplier = (await helper.getHouseDetails(tokenId))[2];
    expectedMul = expectedMul.mul(100).div(gardenMul);
    expect(multiplier.toString()).to.be.equal(expectedMul.toString());

    await game.connect(alice).buyAddon(tokenId, gardenId);
    multiplier = (await helper.getHouseDetails(tokenId))[2];
    expectedMul = expectedMul.mul(gardenMul).div(100);
    expect(multiplier.toString()).to.be.equal(expectedMul.toString());
  });

  it("rare nft should have 5.5 multiplier", async () => {
    let mulRare = await setting.getRareMultiplier();
    await house.mint(alice.address, true, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await game.connect(alice).activateHouse(1);
    const houseData = await helper.getHouseDetails(1);
    expect(houseData[2].toString()).to.be.equal(mulRare.toString());
  })
})
