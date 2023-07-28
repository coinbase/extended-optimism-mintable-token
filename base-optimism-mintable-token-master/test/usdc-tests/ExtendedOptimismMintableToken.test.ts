import { ProxyInstance } from "../@types/generated/contracts/Proxy";
import { ExtendedOptimismMintableTokenInstance } from "../@types/generated/contracts/ExtendedOptimismMintableToken";
import { makeDomainSeparator } from "./helpers";
import { hasSafeAllowance } from "./safeAllowance.behavior";
import { hasGasAbstraction } from "./gasAbstraction.behavior";


const ExtendedOptimismMintableToken = artifacts.require("ExtendedOptimismMintableToken");
const Proxy = artifacts.require("Proxy");

contract("ExtendedOptimismMintableToken",  (accounts) => {
    const admin = accounts[8];
    const bridgeAddress = accounts[9];
    const roleOwnerBlacklisterPauser = accounts[7];
    const remoteTokenAddress = "0xd5e099c71b797516c10ed0f0d895f429c2781142"; // random address
    let extendedOptimismMintableTokenProxy: ProxyInstance;
    let extendedOptimismMintableTokenImpl: ExtendedOptimismMintableTokenInstance;
    let extendedOptimismMintableToken: ExtendedOptimismMintableTokenInstance;
    let domainSeparator: string;

    beforeEach(async () => {
        let initializeCall = web3.eth.abi.encodeFunctionCall({
            name: "initialize",
            type: "function",
            inputs: [{
                type: "string",
                name: "name"
            },
            {
                type: "string",
                name: "symbol"
            },
            {
                type: "address",
                name: "_owner"
            },
            {
                type: "uint8",
                name: "_version"
            }]
        }, ["USD Coin", "USDC.o", roleOwnerBlacklisterPauser, 1]);

        extendedOptimismMintableTokenImpl = await ExtendedOptimismMintableToken.new(
            bridgeAddress,
            remoteTokenAddress,
            "6"
        );
            
        extendedOptimismMintableTokenProxy = await Proxy.new(admin);
        await extendedOptimismMintableTokenProxy.upgradeToAndCall(
            extendedOptimismMintableTokenImpl.address,
            initializeCall,
            { from: admin }
        );

        extendedOptimismMintableToken = await ExtendedOptimismMintableToken.at(extendedOptimismMintableTokenProxy.address);

        // grant roles
        const PAUSER_ROLE = web3.utils.keccak256("roles.pauser");
        const BLACKLISTER_ROLE = web3.utils.keccak256("roles.blacklister");

        await extendedOptimismMintableToken.grantRole(
            PAUSER_ROLE,
            roleOwnerBlacklisterPauser,
            { from: roleOwnerBlacklisterPauser }
        )
        await extendedOptimismMintableToken.grantRole(
            BLACKLISTER_ROLE,
            roleOwnerBlacklisterPauser,
            { from: roleOwnerBlacklisterPauser }
        )

        domainSeparator = makeDomainSeparator(
            "USD Coin",
            "1",
            31337, // hardhat chain id
            extendedOptimismMintableToken.address
        );

        
    })

    hasGasAbstraction(
        () => extendedOptimismMintableToken,
        () => domainSeparator,
        bridgeAddress,
        roleOwnerBlacklisterPauser,
        accounts
    );

    hasSafeAllowance(
        () => extendedOptimismMintableToken,
        roleOwnerBlacklisterPauser,
        accounts
    )

});