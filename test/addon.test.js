const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require('ethereum-waffle');
const { deployContracts, getContracts } = require("./utils/deploy");
const { increaseWorldTimeInSeconds } = require("./utils/helper");
const landshareConstants = require("./utils/constants");
const { BigNumber } = ethers;
use(solidity);

const bn1 = BigNumber.from("1");
const bn10 = BigNumber.from("10");
const bn50 = BigNumber.from("50");
const bn200 = BigNumber.from("200");
const bnDecimalPlaces = BigNumber.from("18");

const tokenDecimals = bn10.pow(bnDecimalPlaces);
const resource1 = bn1.mul(tokenDecimals); 
const resource10 = bn10.mul(tokenDecimals);
const resource200 = bn200.mul(tokenDecimals);
const resource50 = bn50.mul(tokenDecimals);


describe("Addon Contract Test", () => {

  let assetToken;
  let landToken;
  let setting;
  let house;
  let game;
  let stake;

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
    tokenId = 0;
  })

  describe("Buy Addon", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).buyAddon(tokenId, 1)).to.be.revertedWith("BuyAddon: PD");
    })
    it("should return error if addon already bought", async () => {
      await game.connect(alice).buyAddon(tokenId, 1);
      await expect(game.connect(alice).buyAddon(tokenId, 1)).to.be.revertedWith("Addon already bought");
    })
    it("should return error if dependency addon didn't bought", async () => {
      await expect(game.connect(alice).buyAddon(0, 2)).to.be.revertedWith("Need to buy dependency addons");
    })
    it("should return error if it doesn't meet fortification", async () => {
      await game.connect(alice).buyAddon(0, 5)
      await expect(game.connect(alice).buyAddon(0, 7)).to.be.revertedWith("Doesn't meet fortification");
    })
    it("should have addon, cut resource by cost", async () => {
      await game.connect(alice).buyAddon(0, 5); // Alice buy Bathroom Remodel addon.
      const cost = await setting.getBaseAddonCostById(5);
      const resource = await game.getResource(alice.address);
      expect((resource[3].add(cost[3])).toString()).to.be.equal((resource200).toString());

      expect((await house.getHasAddon(0, 5)).toString()).to.be.equal((true).toString());
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyAddon(0, 5); // Buy Bathroom Remodel addon.
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should update house token reward", async () => {
      await game.connect(alice).buyAddon(0, 5); // Buy Bathroom Remodel addon.
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(tokenId);
      const lastTokenRewardTime = data.lastTokenRewardTime;
      expect(latestBlock.timestamp).to.be.equal(lastTokenRewardTime);
    })
    it("should update be able to buy Garden 7 days later", async () => {
      await game.connect(alice).buyAddon(tokenId, 1); // Buy Landscaping
      await game.connect(alice).buyAddon(tokenId, 2); // Buy Garden
      await increaseWorldTimeInSeconds(landshareConstants.interval.sevenAndHalfDay, true); // 7.5 day past
      await game.connect(alice).buyAddon(tokenId, 2); // Buy Garden
    })
    it("should emit 'Buy Addon' event", async () => {
      const receipt = await game.connect(alice).buyAddon(0, 1); // Buy Hardwood Floors.
      await expect(receipt).to.emit(game, 'BuyAddon').withArgs(alice.address, 0, 1);
    })
  })

  describe("Salvage Addon", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
      await game.connect(alice).buyAddon(tokenId, 1); // Buy Landscaping
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).salvageAddon(tokenId, 1)).to.be.revertedWith("Salvage: PD");
    })
    it("should return error if user don't have addon for salvage", async () => {
      await expect(game.connect(alice).salvageAddon(tokenId, 2)).to.be.revertedWith("Addon doesn't exist");
    })
    it("shouldn't have addon, add resource by cost", async () => {
      await game.connect(alice).salvageAddon(tokenId, 1); // Alice salvage Landscaping
      const cost = await setting.getBaseAddonCostById(1);
      const resource = await game.getResource(alice.address);
      expect((resource[1].add(cost[1].mul(25).div(100))).toString()).to.be.equal((resource200).toString());

      expect((await house.getHasAddon(tokenId, 1)).toString()).to.be.equal((false).toString());
    })
    it("should update house token reward", async () => {
      await game.connect(alice).salvageAddon(tokenId, 1); // Alice salvage Landscaping
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(tokenId);
      const lastTokenRewardTime = data.lastTokenRewardTime;
      expect(latestBlock.timestamp).to.be.equal(lastTokenRewardTime);
    })
    it("should emit 'Salvage Addon' event", async () => {
      const receipt = await game.connect(alice).salvageAddon(tokenId, 1); // Salvage Landscaping
      await expect(receipt).to.emit(game, 'SalvageAddon').withArgs(alice.address, tokenId, 1);
    })

    describe("should salvage addons when salavage its dependency", () => {
      it("should salvage garden when salvage landscaping", async () => {
        await game.connect(alice).buyAddon(tokenId, 2); // Buy Garden
        await game.connect(alice).salvageAddon(tokenId, 1); // Salvage Landscaping
  
        expect((await house.getHasAddon(tokenId, 1)).toString()).to.be.equal((false).toString());
        expect((await house.getHasAddon(tokenId, 2)).toString()).to.be.equal((false).toString());
      })
      it("should salvage Jacuzzi Tub when salvage Bathroom Remodel", async () => {
        await game.connect(alice).buyAddon(tokenId, 5); // Buy Bathroom Remodel
        await game.connect(alice).buyAddon(tokenId, 6); // Buy Jacuzzi
        await game.connect(alice).salvageAddon(tokenId, 5); // Salvage Bathroom Remodel
  
        expect((await house.getHasAddon(tokenId, 5)).toString()).to.be.equal((false).toString());
        expect((await house.getHasAddon(tokenId, 6)).toString()).to.be.equal((false).toString());
      })
      it("should salvage Steel Application when salvage Kitchen Model", async () => {
        await game.connect(alice).buyAddon(tokenId, 4); // Buy Kitchen Model
        await game.connect(alice).buyAddon(tokenId, 8); // Buy Steel Application
        await game.connect(alice).salvageAddon(tokenId, 4); // Salvage Kitchen Model
  
        expect((await house.getHasAddon(tokenId, 4)).toString()).to.be.equal((false).toString());
        expect((await house.getHasAddon(tokenId, 8)).toString()).to.be.equal((false).toString());
      })
      it("should salvage Finished Basement when salvage Kitcheck model", async () => {
        await game.connect(alice).buyAddon(tokenId, 4); // Buy Kitchen Model
        await game.connect(alice).buyAddon(tokenId, 5); // Buy Bathroom Remodel
        await game.connect(alice).fortify(tokenId, 2); // Fortify Steel
        await game.connect(alice).buyAddon(tokenId, 10); // Buy Finished Basement
        await game.connect(alice).salvageAddon(tokenId, 4); // Salvage Kitchen Model
  
        expect((await house.getHasAddon(tokenId, 4)).toString()).to.be.equal((false).toString());
        expect((await house.getHasAddon(tokenId, 10)).toString()).to.be.equal((false).toString());
      })
      it("should salvage Finished Basement when salvage Bathroom Remodel", async () => {
        await game.connect(alice).buyAddon(tokenId, 4); // Buy Kitchen Model
        await game.connect(alice).buyAddon(tokenId, 5); // Buy Bathroom Remodel
        await game.connect(alice).fortify(tokenId, 2); // Fortify Steel
        await game.connect(alice).buyAddon(tokenId, 10); // Buy Finished Basement
        await game.connect(alice).salvageAddon(tokenId, 5); // Salvage Kitchen Model
  
        expect((await house.getHasAddon(tokenId, 5)).toString()).to.be.equal((false).toString());
        expect((await house.getHasAddon(tokenId, 10)).toString()).to.be.equal((false).toString());
      })
    });
  })

  describe("Buy Toolshed", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).buyToolshed(tokenId, 1)).to.be.revertedWith("BuyToolshed: PD");
    })
    it("should return error if toolshed type is not valid", async () => {
      await expect(game.connect(alice).buyToolshed(tokenId, 8)).to.be.revertedWith("Invalid Toolshed");
    })
    it("should return error if user already bought toolshed", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1);
      await expect(game.connect(alice).buyToolshed(tokenId, 1)).to.be.revertedWith("Already bought");
    })
    it("should have toolshed, cut resource by cost", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1); // Alice buy toolshed no.1
      const cost = await setting.getToolshedBuildCost(1);
      const resource = await game.getResource(alice.address);
      expect((resource[1].add(cost[1])).toString()).to.be.equal((resource200).toString());

      const toolshed = await house.getToolshed(0);
      expect((toolshed[1]).toString()).to.be.equal((true).toString());
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1); // Alice buy toolshed no.1
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should emit 'Buy Toolshed' event", async () => {
      const receipt = await game.connect(alice).buyToolshed(tokenId, 1); // buy toolshed no.1
      await expect(receipt).to.emit(game, 'BuyToolshed').withArgs(alice.address, 0, 1);
    })
  })

  describe("Switch Toolshed", () => {
    let blockTime_01;
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      blockTime_01 = await ethers.provider.getBlock("latest");
      await setting.connect(admin).setPowerLimit([220, 230, 240, 250, 260]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).switchToolshed(0, 1)).to.be.revertedWith("SwitchToolshed: PD");
    })
    it("should return error if toolshed type is not valid", async () => {
      await expect(game.connect(alice).switchToolshed(0, 6)).to.be.revertedWith("Invalid type");
    })
    it("should return error if toolshed is not active", async () => {
      await expect(game.connect(alice).switchToolshed(0, 1)).to.be.revertedWith("Doesn't have an active one");
    })
    it("should return error if user didn't buy the toolshed to switch", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1);
      await expect(game.connect(alice).switchToolshed(0, 2)).to.be.revertedWith("Did not buy yet");
    })
    it("should have activate toolshed, cut resource by cost", async () => {
      let windFarm = 0;
      await game.connect(alice).buyToolshed(tokenId, 1); // Alice buy toolshed no.1
      await game.connect(alice).buyToolshed(tokenId, 2); // Alice buy toolshed no.2
      await game.connect(alice).switchToolshed(0, 1);
      const blockTime_02 = await ethers.provider.getBlock("latest");
      const powerV1Amount = await setting.getResourceGenerationAmount(windFarm, 1);
      let powerAmountGenerated = powerV1Amount.mul(BigNumber.from(blockTime_02.timestamp - blockTime_01.timestamp)).div(BigNumber.from(landshareConstants.interval.oneDay));
      
      const cost1 = await setting.getToolshedBuildCost(1);
      const cost2 = await setting.getToolshedBuildCost(2);
      const switchCost = await setting.getToolshedSwitchCost();
      const resource = await game.getResource(alice.address);

      expect((((resource[0].add(cost1[0])).add(cost2[0])).add(switchCost[0]).sub(powerAmountGenerated)).toString()).to.be.equal((resource200).toString());

      const toolshed = await house.getToolshed(0);
      expect((toolshed[1]).toString()).to.be.equal((true).toString());
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1); // Alice buy toolshed no.1
      await game.connect(alice).buyToolshed(tokenId, 2); // Alice buy toolshed no.2
      await game.connect(alice).switchToolshed(0, 1);
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should emit 'Switch Toolshed' event", async () => {
      await game.connect(alice).buyToolshed(tokenId, 1); // Alice buy toolshed no.1
      await game.connect(alice).buyToolshed(tokenId, 2); // Alice buy toolshed no.2
      const receipt = await game.connect(alice).switchToolshed(0, 1); // switch toolshed no.1
      await expect(receipt).to.emit(game, 'SwitchToolshed').withArgs(alice.address, 0, 2, 1);
    })
  })

  describe("Buy Fireplace", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).buyFireplace(0)).to.be.revertedWith("BuyFireplace: PD");
    })
    it("should return error if user already have fireplace", async () => {
      await game.connect(alice).buyFireplace(0);
      await expect(game.connect(alice).buyFireplace(0)).to.be.revertedWith("Already have fireplace");
    })
    it("should have fireplace, cut resource by cost", async () => {
      await game.connect(alice).buyFireplace(0); // Alice buy fireplace
      const cost = await setting.getFireplaceCost();
      const resource = await game.getResource(alice.address);

      expect((resource[2].add(cost[2])).toString()).to.be.equal((resource200).toString());

      expect((await house.getHasFireplace(0)).toString()).to.be.equal((true).toString());
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyFireplace(0); // Alice buy fireplace
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should emit 'Buy Fireplace' event", async () => {
      const receipt = await game.connect(alice).buyFireplace(0); // buy fireplace
      await expect(receipt).to.emit(game, 'BuyFireplace').withArgs(alice.address, 0);
    })
  })

  describe("Burn lumber to make power", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [80, 50, 50, 50, 50]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).burnLumberToMakePower(0, resource10)).to.be.revertedWith("BurnLumber: PD");
    })
    it("should return error if user don't have fireplace", async () => {
      await expect(game.connect(alice).burnLumberToMakePower(0, resource10)).to.be.revertedWith("Fireplace need to be purchased");
    })
    it("should return error if user don't have insufficient lumber", async () => {
      await game.connect(alice).buyFireplace(0);
      await expect(game.connect(alice).burnLumberToMakePower(0, resource200)).to.be.revertedWith("Insufficient lumber");
    })
    it("should return error if user exceed max power limit", async () => {
      await game.connect(alice).buyFireplace(0);
      await expect(game.connect(alice).burnLumberToMakePower(0, resource50)).to.be.revertedWith("Exceed the max power limit");
    })
    it("should have added power, cut lumber to resource", async () => {
      await game.connect(alice).buyFireplace(0); // Alice buy fireplace
      const resource = await game.getResource(alice.address);
      await game.connect(alice).burnLumberToMakePower(0, resource1);
      const updatedResource = await game.getResource(alice.address);

      expect((updatedResource[1].add(resource1)).toString()).to.be.equal((resource50).toString());

      // const ratio = await setting.getFireplaceBurnRatio();
      // expect(resource[0].add(resource10.mul(ratio).div(100))).to.be.equal(updatedResource[0]).toString();
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyFireplace(0); // Alice buy fireplace
      await game.connect(alice).burnLumberToMakePower(0, resource1);
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should emit 'Burn Lumber' event", async () => {
      await game.connect(alice).buyFireplace(0);
      const receipt = await game.connect(alice).burnLumberToMakePower(0, resource1); // Bunn 1 lumber to make power
      const generatedPower = resource1.mul(await setting.getFireplaceBurnRatio() / 100);
      await expect(receipt).to.emit(game, 'BurnLumber').withArgs(alice.address, 0, tokenDecimals, BigNumber.from(generatedPower.toString()));
    })
  })

  describe("Buy Harvester", () => {
    beforeEach(async function() {
      await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
      await game.connect(alice).activateHouse(tokenId);
      await setting.connect(admin).setPowerLimit([200, 220, 230, 240, 250]);
      await game.addResourceByAdmin(alice.address, [200, 200, 200, 200, 200]);
    })
    it("should return error if user don't have ownership of houseNFT", async () => {
      await expect(game.connect(bob).buyHarvester(0)).to.be.revertedWith("BuyHarvester: PD");
    })
    it("should return error if user already have harvester", async () => {
      await game.connect(alice).buyHarvester(0);
      await expect(game.connect(alice).buyHarvester(0)).to.be.revertedWith("Already have harvester");
    })
    it("should have harvester, cut resource by cost", async () => {
      await game.connect(alice).buyHarvester(0); // Alice buy harvester

      const cost = await setting.getHarvesterCost();
      const resource = await game.getResource(alice.address);

      expect((resource[4].add(cost[4])).toString()).to.be.equal((resource200).toString());

      expect((await house.getHasHarvester(0)).toString()).to.be.equal((true).toString());
    })
    it("should auto power harvest", async () => {
      await game.connect(alice).buyHarvester(0); // Alice buy harvester
      const latestBlock = await ethers.provider.getBlock("latest");
      const data = await house.getHouse(0);
      const lastPowerUpdatedTime = data.lastResourceRewardTime[0];
      expect(latestBlock.timestamp).to.be.equal(lastPowerUpdatedTime);
    })
    it("should emit 'Buy Harvester' event", async () => {
      const receipt = await game.connect(alice).buyHarvester(0); // buy harvester
      await expect(receipt).to.emit(game, 'BuyHarvester').withArgs(alice.address, 0);
    })
  });  

})
