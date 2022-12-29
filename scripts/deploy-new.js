// scripts/deploy-fake-asset.js
const hre = require("hardhat");
const { BigNumber } = hre.ethers;

async function main () {
  const accounts = await hre.ethers.getSigners();
  const admin = accounts[0], alice = accounts[1];

  // // Deploy fake asset token
  // const AssetToken = await hre.ethers.getContractFactory('LS81712NFToken');
  // console.log('Deploying assetToken...');
  // const assetToken = await AssetToken.connect(admin).deploy();
  // await assetToken.deployed();
  // console.log('AssetToken deployed to:', assetToken.address);

  // // Deploy LandToken
  // const LandToken = await hre.ethers.getContractFactory('LandToken');
  // console.log('Deploying LandToken...');
  // const landToken = await LandToken.deploy();
  // await landToken.deployed();
  // console.log('LandToken deployed to:', landToken.address);

  // // Deploy LandTokenStake
  // const LandTokenStake = await hre.ethers.getContractFactory('LandTokenStake');
  // console.log('Deploying LandTokenStake...');
  // const landTokenStake = await LandTokenStake.deploy(landToken.address, admin.address);
  // await landTokenStake.deployed();
  // console.log('LandTokenStake deployed to:', landTokenStake.address);

  // // Deploy BuyBack contract
  // const BuyBack = await hre.ethers.getContractFactory('buyback');
  // console.log('Deploying BuyBack...');
  // const buyback = await BuyBack.deploy(landToken.address, landTokenStake.address);
  // await buyback.deployed();
  // console.log('BuyBack deployed to:', buyback.address);

  // // Deploy BEP20Token
  // const BEP20Token = await hre.ethers.getContractFactory('BEP20Token');
  // console.log('Deploying BEP20Token...');
  // const bep20Token = await BEP20Token.deploy();
  // await bep20Token.deployed();
  // console.log('BEP20Token deployed to:', bep20Token.address);

  // // Deploy Stake(origin)
  // const StakeOrigin = await hre.ethers.getContractFactory('stake');
  // console.log('Deploying StakeOrigin...');
  // const stakeOrigin = await StakeOrigin.deploy(landToken.address, buyback.address, admin.address, bep20Token.address);
  // await stakeOrigin.deployed();
  // console.log('StakeOrigin deployed to:', stakeOrigin.address);

  // // Deploy LandTokenStakingV2
  // const LandTokenStakingV2 = await hre.ethers.getContractFactory('LandTokenStakingV2');
  // console.log('Deploying LandTokenStakingV2...');
  // const landTokenStakingV2 = await LandTokenStakingV2.deploy(bep20Token.address, landToken.address, admin.address, 10, 0, 10000000000);
  // await landTokenStakingV2.deployed();
  // console.log('LandTokenStakingV2 deployed to:', landTokenStakingV2.address);

  // // Deploy CoinPair
  // const CoinPair = await hre.ethers.getContractFactory('ApePair');
  // console.log('Deploying CoinPair...');
  // const coinPair = await CoinPair.deploy();
  // await coinPair.deployed();
  // console.log('CoinPair deployed to:', coinPair.address);

  // // Deploy BnbPair
  // const BnbPair = await hre.ethers.getContractFactory('ApePair');
  // console.log('Deploying BnbPair...');
  // const bnbPair = await BnbPair.deploy();
  // await bnbPair.deployed();
  // console.log('BnbPair deployed to:', bnbPair.address);

  // // Deploy Claim
  // const Claim = await hre.ethers.getContractFactory('claim');
  // console.log('Deploying Claim...');
  // const claim = await Claim.deploy([admin.address, alice.address], [1000, 1000000], admin.address, landToken.address);
  // await claim.deployed();
  // console.log('Claim deployed to:', claim.address);


  // // Deploy Setting contract
  // const Setting = await hre.ethers.getContractFactory('Setting');
  // console.log('Deploying Setting...');
  // const setting = await Setting.deploy();
  // await setting.deployed();
  // console.log('Setting deployed to:', setting.address);

  // // Deploy House contract
  // const House = await hre.ethers.getContractFactory('HouseNFT');
  // console.log('Deploying House NFT...');
  // const house = await House.deploy('Land House', 'LSH', 10, setting.address);
  // await house.deployed();
  // console.log('House deployed to:', house.address);

  // // Deploy Helper contract
  // const Helper = await hre.ethers.getContractFactory('Helper');
  // console.log('Deploying Helper...');
  // const helper = await Helper.deploy(setting.address, house.address);
  // await helper.deployed();
  // console.log('Helper deployed to:', helper.address);

  // // Deploy Validator contract
  // const Validator = await hre.ethers.getContractFactory('Validator');
  // console.log('Deploying Validator...');
  // const validator = await Validator.deploy(
  //   landToken.address, // LandToken Address
  //   setting.address, // Setting Address
  //   house.address, // House Address
  //   helper.address // Helper Address
  // );
  // await validator.deployed();
  // console.log('Validator deployed to:', validator.address);

  // Deploy Game contract
  const Game = await hre.ethers.getContractFactory('Game');
  console.log('Deploying Game...');
  const game = await Game.deploy(
    "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", // LandToken Address
   "0x610178dA211FEF7D417bC0e6FeD39F05609AD788", // Setting Address
    "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e", // House Address
    "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0", // Helper Address
   "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82" // Validator Address
  );
  await game.deployed();
  console.log('Game deployed to:', game.address);

  // // Deploy Stake contract
  // const Stake = await hre.ethers.getContractFactory('Stake');
  // console.log('Deploying Stake...');
  // const stake = await Stake.deploy(
  //   house.address, // House Address
  //   assetToken.address, // AssetToken Address
  //   landToken.address // LandToken Address
  // );
  // await stake.deployed();
  // console.log('Stake deployed to:', stake.address);

  
  // Set setting, house and stake contract addresses in game contract
  await game.setContractAddress( 
    "0x610178dA211FEF7D417bC0e6FeD39F05609AD788", //setting ADDRESS
    "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e", // House Address
   "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0", // Helper Address
   "0x0B306BF915C4d645ff596e518fAf3F9669b97016", //stake
  "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82" // Validator Address
  );


  const houseNFTAddress = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e';
  const stakeAddress = '0x0B306BF915C4d645ff596e518fAf3F9669b97016'
  const validatorAddress = '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82';
  const House = await ethers.getContractFactory('HouseNFT');
  const house = await House.attach(houseNFTAddress);
  const Stake = await ethers.getContractFactory('Stake');
  const stake = await Stake.attach(stakeAddress)
  const Validator = await ethers.getContractFactory('Validator');
  const validator = await Validator.attach(validatorAddress); 

  // Set stakeContractAddress and gameContractAddress in house.
  await house.connect(admin).setContractAddress("0x610178dA211FEF7D417bC0e6FeD39F05609AD788", "0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0", game.address, "0x0B306BF915C4d645ff596e518fAf3F9669b97016", "0x5FbDB2315678afecb367f032d93F642f64180aa3");

  // Set Game contract address to validator contract
  await validator.setGameContractAddress(game.address);



  // Add alice to whitelist
//   await assetToken.addWhitelister(admin.address);
//   await assetToken.connect(admin).addAddressToWhitelist(alice.address);

  // Mint for test
//   await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
//   await house.mint(admin.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
//   await house.mint(admin.address, true, "ipfs://QmQP6gfqqCW1d82empnqybRKiRNrkdbubFDUC5N8ZutEEv");

//   await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
//   await house.mint(alice.address, false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");

  console.log("token URI", await house.tokenURI(0));

  // Give some resource to admin for test
  await game.addResourceByAdmin(admin.address, [0, 500, 500, 500, 500]);

//   // Give 1000 ETH land token to game contract
//   await landToken.transfer(game.address, BigNumber.from("3000").mul(BigNumber.from("10").pow(BigNumber.from("18"))));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
  