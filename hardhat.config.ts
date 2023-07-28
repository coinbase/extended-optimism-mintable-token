import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-truffle5";
import '@nomiclabs/hardhat-web3'
import '@typechain/hardhat'
import '@nomicfoundation/hardhat-ethers'
import '@nomicfoundation/hardhat-chai-matchers'
import "@nomicfoundation/hardhat-foundry";
import 'hardhat-contract-sizer';
import 'solidity-coverage';

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
    contractSizer: {
        runOnCompile: false
    },
    solidity: {
        compilers: [
            {
                version: "0.8.15",
                settings: {
                    optimizer: {
                      enabled: true,
                      runs: 999999
                    }
                },
            },
        ],
    },
    typechain: {
        outDir: "@types/generated",
        target: "truffle-v5",
    },
    paths: {
        sources: "./src",
    },
    mocha: {
        timeout: 0
    },
};

export default config;