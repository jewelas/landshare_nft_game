require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');
require("hardhat-gas-reporter");

const secrets = require('./secrets.json');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "localhost",
  networks: {
    hardhat: {
      mining: {
        auto: true,
        interval: 10000
      }
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: {mnemonic: secrets.mnemonic}
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: {mnemonic: secrets.mnemonic}
    }
  },
  etherscan: {
    apiKey: secrets.bscscanApiKey
  },
  solidity: {
    compilers: [
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    overrides: {
      "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol": {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1337,
          },
        }
      },
      "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol": {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1337,
          },
        }
      },
      "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol": {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1337,
          },
        }
      },
      "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol": {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1337,
          },
        }
      },
    }
  },
  contractSizer: {
    runOnCompile: true,
    strict: true,
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 21,
    enabled: false,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};
