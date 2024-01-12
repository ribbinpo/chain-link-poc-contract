import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import { getAccounts } from "./utils/account.util";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {},
      },
    ],
  },
  networks: {
    "bsc-testnet": {
      url: process.env.URL_BSC_TESTNET || "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
      accounts: getAccounts(),
    },
    mumbai: {
      url: process.env.URL_MUMBAI || "https://polygon-testnet.public.blastapi.io",
      accounts: getAccounts(),
    },
    sepolia: {
      url: process.env.URL_SEPOLIA || "https://eth-sepolia.public.blastapi.io",
      accounts: getAccounts(),
    },
  },
  gasReporter: {
    enabled: process.env.GAS_REPORT === "true",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
  paths: {
    sources: "./contracts",
    tests: "/test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
