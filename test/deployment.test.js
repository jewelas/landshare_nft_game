const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployContracts, getContracts } = require("./utils/deploy");

describe("Deployment Test", () => {

  let assetToken;
  let landToken;
  let house;
  let helper;
  let game;
  let stake;

  beforeEach(async function() {
    const accounts = await ethers.getSigners();
    admin = accounts[0], alice = accounts[1], bob = accounts[2];

    await deployContracts();

    assetToken = getContracts().assetToken;
    landToken = getContracts().landToken;
    house = getContracts().house;
    helper = getContracts().helper;
    game = getContracts().game;
    stake = getContracts().stake;
  })

  it('should succeed deploying contracts', () => {})
  
})
  