// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";

contract DeployExtendedOptimismMintableToken is Script {
    bytes32 public constant PAUSER_ROLE = keccak256("roles.pauser");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("roles.blacklister");

    address public admin = vm.envAddress("ADMIN");
    address public owner = vm.envAddress("OWNER");
    address public pauser = vm.envAddress("PAUSER");
    address public blacklister = vm.envAddress("BLACKLISTER");
    address public remoteToken = vm.envAddress("REMOTE_TOKEN");
    uint8 public decimals = uint8(vm.envUint("DECIMALS")); 
    string public name = vm.envString("NAME");
    string public symbol = vm.envString("SYMBOL");

    function run()
        public returns(address)
    {
        console.log("Admin: %s", admin);
        console.log("L2 Bridge: %s", Predeploys.L2_STANDARD_BRIDGE);
        console.log("Remote Token: %s", remoteToken);
        console.log("Name: %s", name);
        console.log("Symbol: %s", symbol);
        console.log("Pauser: %s", pauser);
        console.log("Blacklister: %s", blacklister);
        console.log("Owner: %s", owner);
        console.log("Decimals: %s", decimals);

        vm.broadcast();
        ExtendedOptimismMintableToken extendedOptimismMintableTokenImpl = new ExtendedOptimismMintableToken(
            Predeploys.L2_STANDARD_BRIDGE,
            remoteToken,
            decimals
        );

        require(extendedOptimismMintableTokenImpl.BRIDGE() == Predeploys.L2_STANDARD_BRIDGE, 
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
            symbol
        );
        
        vm.broadcast(admin);
        extendedOptimismMintableTokenProxy.upgradeToAndCall(address(extendedOptimismMintableTokenImpl), initializeCall);
        // Ensure that contract is properly initialized
        // 0 is the storage slot for `_initialized` from https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/0a2cb9a445c365870ed7a8ab461b12acf3e27d63/contracts/proxy/utils/Initializable.sol#L62
        uint64 initializedVersion = uint64(uint(vm.load(
            address(extendedOptimismMintableToken),
             0
        )));
        require(initializedVersion == 1, "DeployExtendedOptimismMintableToken: initialized version is not 1 after calling `initialize`");
        require(keccak256(abi.encode(extendedOptimismMintableToken.name())) == keccak256(abi.encode(name)), "DeployExtendedOptimismMintableToken: token name incorrect");
        require(keccak256(abi.encode(extendedOptimismMintableToken.symbol())) == keccak256(abi.encode(symbol)), "DeployExtendedOptimismMintableToken: token symbol incorrect");
        require(extendedOptimismMintableToken.BRIDGE() == Predeploys.L2_STANDARD_BRIDGE, 
            "DeployExtendedOptimismMintableToken: token l2Bridge incorrect"
        );
        require(extendedOptimismMintableToken.REMOTE_TOKEN() == remoteToken, 
            "DeployExtendedOptimismMintableToken: token remoteToken incorrect"
        );
        require(extendedOptimismMintableToken.decimals() == decimals, 
            "DeployExtendedOptimismMintableToken: token decimals incorrect"
        );

        console.log("extendedOptimismMintableToken initialized"); 

        vm.prank(address(0));
        require(extendedOptimismMintableTokenProxy.admin() == admin, "DeployExtendedOptimismMintableToken: proxy admin transfer failed");

        vm.broadcast(admin);
        extendedOptimismMintableToken.initializeV2(name, symbol, owner);

        vm.broadcast(owner);
        extendedOptimismMintableToken.grantRole(PAUSER_ROLE, pauser);
        vm.broadcast(owner);
        extendedOptimismMintableToken.grantRole(BLACKLISTER_ROLE, blacklister);
        require(extendedOptimismMintableToken.hasRole(PAUSER_ROLE, pauser),
            "DeployExtendedOptimismMintableToken: pauser role is incorrect" 
        );
        require(extendedOptimismMintableToken.hasRole(BLACKLISTER_ROLE, blacklister),
            "DeployExtendedOptimismMintableToken: blacklister role is incorrect" 
        );

        // Ensure that contract is properly initialized
        // 0 is the storage slot for `_initialized` from https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/0a2cb9a445c365870ed7a8ab461b12acf3e27d63/contracts/proxy/utils/Initializable.sol#L62
        uint64 initializedVersion2 = uint64(uint(vm.load(
            address(extendedOptimismMintableToken),
             0
        )));
        require(initializedVersion2 == 2, "DeployExtendedOptimismMintableToken: initialized version is not 2 after calling `initializev2`");

        return address(extendedOptimismMintableToken);
    }
}
