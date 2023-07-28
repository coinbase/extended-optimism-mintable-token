// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";

contract DeployExtendedOptimismMintableToken is Script {
    bytes32 public constant PAUSER_ROLE = keccak256("roles.pauser");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("roles.blacklister");

    function run(
        address deployer,
        address admin,
        address l2Bridge,
        address remoteToken,
        string memory name,
        string memory symbol,
        address pauser,
        address blacklister,
        address owner,
        uint8 decimals
    )
        public
    {
        console.log("Admin: %s", admin);
        console.log("L2 Bridge: %s", l2Bridge);
        console.log("Remote Token: %s", remoteToken);
        console.log("Name: %s", name);
        console.log("Symbol: %s", symbol);
        console.log("Pauser: %s", pauser);
        console.log("Blacklister: %s", blacklister);
        console.log("Owner: %s", owner);
        console.log("Decimals: %s", decimals);

        vm.broadcast();
        ExtendedOptimismMintableToken extendedOptimismMintableTokenImpl = new ExtendedOptimismMintableToken(
            l2Bridge,
            remoteToken,
            decimals
        );

        require(extendedOptimismMintableTokenImpl.BRIDGE() == l2Bridge, 
            "DeployExtendedOptimismMintableToken: token l2Bridge incorrect")
        ;
        require(extendedOptimismMintableTokenImpl.REMOTE_TOKEN() == remoteToken, 
            "DeployExtendedOptimismMintableToken: token remoteToken incorrect"
        );
        require(extendedOptimismMintableTokenImpl.decimals() == decimals, 
            "DeployExtendedOptimismMintableToken: token decimals incorrect"
        );

        console.log("extendedOptimismMintableToken implementation deployed to %s", address(extendedOptimismMintableTokenImpl));

        vm.broadcast();
        Proxy extendedOptimismMintableTokenProxy = new Proxy(admin);
        ExtendedOptimismMintableToken extendedOptimismMintableToken = ExtendedOptimismMintableToken(address(extendedOptimismMintableTokenProxy));

        console.log("extendedOptimismMintableToken proxy deployed to %s", address(extendedOptimismMintableTokenProxy));

        bytes memory initializeCall = abi.encodeWithSelector(
            extendedOptimismMintableTokenImpl.initialize.selector,
            name,
            symbol,
            owner,
            1
        );
        
        extendedOptimismMintableTokenProxy.upgradeToAndCall(address(extendedOptimismMintableTokenImpl), initializeCall);
        require(keccak256(abi.encode(extendedOptimismMintableToken.name())) == keccak256(abi.encode(name)), "DeployExtendedOptimismMintableToken: token name incorrect");
        require(keccak256(abi.encode(extendedOptimismMintableToken.symbol())) == keccak256(abi.encode(symbol)), "DeployExtendedOptimismMintableToken: token symbol incorrect");

        console.log("extendedOptimismMintableToken initialized"); 

        vm.broadcast(deployer);
        extendedOptimismMintableTokenProxy.changeAdmin(admin);
        vm.broadcast(address(0));
        require(extendedOptimismMintableTokenProxy.admin() == admin, "DeployExtendedOptimismMintableToken: proxy admin transfer failed");

        vm.broadcast(owner);
        extendedOptimismMintableToken.grantRole(PAUSER_ROLE, pauser);
        vm.broadcast(owner);
        extendedOptimismMintableToken.grantRole(BLACKLISTER_ROLE, blacklister);
    }
}
