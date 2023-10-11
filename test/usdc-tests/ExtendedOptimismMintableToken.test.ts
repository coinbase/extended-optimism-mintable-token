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
    const rolesAdminBlacklisterPauser = accounts[7];
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
                name: "_name"
            },
            {
                type: "string",
                name: "_symbol"
            }
        ]
        }, ["USD Coin", "USDC"]);

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

        await extendedOptimismMintableToken.initializeV2(
            "USD Coin", 
            rolesAdminBlacklisterPauser, 
            { from: admin }
        );

        // grant roles
        const PAUSER_ROLE = web3.utils.keccak256("roles.pauser");
        const BLACKLISTER_ROLE = web3.utils.keccak256("roles.blacklister");

        await extendedOptimismMintableToken.grantRole(
            PAUSER_ROLE,
            rolesAdminBlacklisterPauser,
            { from: rolesAdminBlacklisterPauser }
        )
        await extendedOptimismMintableToken.grantRole(
            BLACKLISTER_ROLE,
            rolesAdminBlacklisterPauser,
            { from: rolesAdminBlacklisterPauser }
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
        rolesAdminBlacklisterPauser,
        accounts
    );

    hasSafeAllowance(
        () => extendedOptimismMintableToken,
        rolesAdminBlacklisterPauser,
        accounts
    )

});