// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { Predeploys } from "@eth-optimism-bedrock/contracts/libraries/Predeploys.sol";

contract UpgradeToExtendedOptimismMintableToken is Script {
    bytes32 public constant PAUSER_ROLE = keccak256("roles.pauser");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("roles.blacklister");

    address payable public newImplementation = payable(vm.envAddress("NEW_IMPLEMENTATION_ADDRESS"));
    address payable public proxy = payable(vm.envAddress("PROXY_ADDRESS"));
    address public admin = vm.envAddress("ADMIN_ADDRESS");
    address public rolesAdmin = vm.envAddress("DEFAULT_ROLE_ADMIN_ADDRESS");
    address public pauser = vm.envAddress("PAUSER_ADDRESS");
    address public blacklister = vm.envAddress("BLACKLISTER_ADDRESS");

    function run()
        public
    {
        UpgradeableOptimismMintableERC20 upgradeableOptimismMintableERC20 = UpgradeableOptimismMintableERC20(payable(address(proxy)));
        string memory name = upgradeableOptimismMintableERC20.name();
        string memory symbol = upgradeableOptimismMintableERC20.symbol();
        address remoteToken = upgradeableOptimismMintableERC20.REMOTE_TOKEN();
        uint8 decimals = upgradeableOptimismMintableERC20.decimals();

        // Ensure that contract is properly initialized
        // 0 is the storage slot for `_initialized` from https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/0a2cb9a445c365870ed7a8ab461b12acf3e27d63/contracts/proxy/utils/Initializable.sol#L62
        uint64 initializedVersionPreUpgrade = uint64(uint(vm.load(
            address(upgradeableOptimismMintableERC20),
             0
        )));
        require(initializedVersionPreUpgrade == 1, "UpgradeToExtendedOptimismMintableToken: initialized version is not 1 prior to attempting upgrade");

        console.log("Proxy: %s", proxy);
        console.log("New Implementation: %s", newImplementation);
        console.log("L2 Bridge: %s", Predeploys.L2_STANDARD_BRIDGE);
        console.log("Remote Token: %s", remoteToken);
        console.log("Decimals: %s", decimals);
        console.log("Name: %s", name);
        console.log("Symbol: %s", symbol);
        console.log("RolesAdmin: %s", rolesAdmin);
        console.log("Pauser: %s", pauser);
        console.log("Blacklister: %s", blacklister);


        Proxy extendedOptimismMintableTokenProxy = Proxy(proxy);
        ExtendedOptimismMintableToken extendedOptimismMintableToken = ExtendedOptimismMintableToken(proxy);
        bytes memory initializeCall = abi.encodeWithSelector(
            ExtendedOptimismMintableToken.initializeV2.selector,
            name,
            rolesAdmin
        );

        vm.broadcast(admin);
        extendedOptimismMintableTokenProxy.upgradeToAndCall(newImplementation, initializeCall);
        require(keccak256(abi.encode(extendedOptimismMintableToken.name())) == keccak256(abi.encode(name)), "UpgradeToExtendedOptimismMintableToken: token name incorrect");
        require(keccak256(abi.encode(extendedOptimismMintableToken.symbol())) == keccak256(abi.encode(symbol)), "UpgradeToExtendedOptimismMintableToken: token symbol incorrect");
        require(extendedOptimismMintableToken.BRIDGE() == Predeploys.L2_STANDARD_BRIDGE, 
            "UpgradeToExtendedOptimismMintableToken: token l2Bridge incorrect"
        );
        require(extendedOptimismMintableToken.REMOTE_TOKEN() == remoteToken, 
            "UpgradeToExtendedOptimismMintableToken: token remoteToken incorrect"
        );
        require(extendedOptimismMintableToken.decimals() == decimals, 
            "UpgradeToExtendedOptimismMintableToken: token decimals incorrect"
        );

        // Ensure that contract is properly initialized
        // 0 is the storage slot for `_initialized` from https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/0a2cb9a445c365870ed7a8ab461b12acf3e27d63/contracts/proxy/utils/Initializable.sol#L62
        uint64 initializedVersionPostUpgrade = uint64(uint(vm.load(
            address(extendedOptimismMintableToken),
             0
        )));
        require(initializedVersionPostUpgrade == 2, "UpgradeToExtendedOptimismMintableToken: initialized version is not 2 following attempted upgrade");

        console.log("extendedOptimismMintableToken initialized"); 

        vm.broadcast(rolesAdmin);
        extendedOptimismMintableToken.grantRole(PAUSER_ROLE, pauser);
        vm.broadcast(rolesAdmin);
        extendedOptimismMintableToken.grantRole(BLACKLISTER_ROLE, blacklister);
        require(extendedOptimismMintableToken.hasRole(PAUSER_ROLE, pauser),
            "DeployExtendedOptimismMintableToken: pauser role is incorrect" 
        );
        require(extendedOptimismMintableToken.hasRole(BLACKLISTER_ROLE, blacklister),
            "DeployExtendedOptimismMintableToken: blacklister is role incorrect" 
        );
    }
}
