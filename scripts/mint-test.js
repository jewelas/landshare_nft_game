// scripts/mint.js
const hre = require("hardhat");
const { BigNumber } = hre.ethers;

async function main () {
  const accounts = await hre.ethers.getSigners();
  const admin = accounts[0], alice = accounts[1];

  const houseNFTAddress = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e';
  const House = await ethers.getContractFactory('HouseNFT');
  const house = await House.attach(houseNFTAddress);

  const userAddress = [
      '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266',
      '0x70997970c51812dc3a010c7d01b50e0d17dc79c8',
      '0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc',
      '0x90f79bf6eb2c4f870365e785982e1f101e93b906'
  ]

  for (var i = 0; i < userAddress.length; i++) {
    await house.mint(userAddress[i], false, "ipfs://Qmdv3Te1sUd49eHUnxGoFvTV9hN4X5KdsfmmKLcvAjoMb4");
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
  