require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 7545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
    },
    ropsten: {
      provider: () =>
        new HDWalletProvider(
          process.env.ROPSTEN_PK,
          `https://ropsten.infura.io/v3/${process.env.INFURA_ID}`
        ),
      network_id: 3,
      gas: 4698712,
      gasPrice: 30000000000,
    },
    live: {
      provider: () =>
        new HDWalletProvider(
          process.env.LIVE_PK,
          `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`
        ),
      network_id: 1,
      gas: 4698712,
      gasPrice: 80000000000,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      // optimizer: {
      //   enabled: false,
      //   runs: 200,
      // },
      //  evmVersion: "byzantium"
      // }
    },
  },
};
