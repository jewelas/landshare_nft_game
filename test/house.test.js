const { use, expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("./utils/deploy");
const landshareConstants = require("./utils/constants");
const { solidity } = require('ethereum-waffle');
const { BigNumber } = ethers;
use(solidity);


describe("House Contract Test", () => {

  let assetToken;
  let landToken;
  let house;
  let game;
  let stake;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    assetToken = getContracts().assetToken;
    landToken = getContracts().landToken;
    house = getContracts().house;
    game = getContracts().game;
    stake = getContracts().stake;
  })

  it('should have correct name', async () => {
    expect(await house.name()).to.be.equal(landshareConstants.house.name);
  })
  it('should have correct symbol', async () => {
    expect(await house.symbol()).to.be.equal(landshareConstants.house.symbol);
  })
  it('should be mintable by admin', async() => {
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    expect((await house.balanceOf(alice.address)).toString()).to.be.equal("1");
  })
  it('should revert if other user try mint', async () => {
    await expect(house.connect(bob).mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4")).to.be.revertedWith("Ownable: caller is not the owner");
  })
  it('should return correct index of NFTs from getHousesByOwner', async () => {
    await assetToken.connect(admin).addAddressToWhitelist(bob.address);

    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await house.mint(bob.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    const housesOfAlice = await house.getHousesByOwner(alice.address);
    expect(housesOfAlice.toString()).to.be.equal(([0, 2]).toString());
  })
  it('should return correct house Name and series when initialize', async () => {
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    const data = await house.getHouse(0);
    expect(data.name).to.be.equal("LSNF");
    expect(data.series).to.be.equal("817 12th Ave N");
  })
  it('should return correct house Name and series after set', async () => {
    await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    await house.connect(alice).setHouseName(0, "test");
    const data = await house.getHouse(0);
    expect(data.name).to.be.equal("test");
  })
  it('should revert if rare house is be minting over max limt', async () => {
    for (let i = 0; i < 10; i++) {
      await house.mint(admin.address, true, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
    }

    await expect(house.mint(admin.address, true, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4")).to.be.revertedWith("Limited to mint rare houses");
  })
})
