// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Common_Test } from "test/CommonTest.t.sol";
import { UpgradeToExtendedOptimismMintableToken } from "script/UpgradeToExtendedOptimismMintableToken.s.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { ExtendedOptimismMintableToken } from "src/ExtendedOptimismMintableToken.sol";
import { UpgradeableOptimismMintableERC20 } from "src/UpgradeableOptimismMintableERC20.sol";

contract UpgradeToExtendedOptimismMintableToken_Test is Common_Test {    
    UpgradeToExtendedOptimismMintableToken upgraderImpl;

    function setUp() public virtual override {
        super.setUp();

        ExtendedOptimismMintableTokenProxy = new Proxy(admin);
        L2Token = ExtendedOptimismMintableToken(address(ExtendedOptimismMintableTokenProxy));

        bytes memory initializeCall = abi.encodeCall(
            UpgradeableOptimismMintableERC20.initialize, 
            (
                string(abi.encodePacked("L2-", L1Token.name())),
                string(abi.encodePacked("L2-", L1Token.symbol()))
            )
        );
        vm.prank(admin);
        ExtendedOptimismMintableTokenProxy.upgradeToAndCall(address(L2TokenImplV1), initializeCall);

        vm.setEnv("NEW_IMPLEMENTATION_ADDRESS", vm.toString(address(L2TokenImpl)));
        vm.setEnv("PROXY_ADDRESS", vm.toString(address(L2Token)));
        vm.setEnv("ADMIN_ADDRESS", vm.toString(admin));
        vm.setEnv("OWNER_ADDRESS", vm.toString(owner));
        vm.setEnv("PAUSER_ADDRESS", vm.toString(pauser));
        vm.setEnv("BLACKLISTER_ADDRESS", vm.toString(blacklister));
        
        upgraderImpl = new UpgradeToExtendedOptimismMintableToken();
    }

    function test_upgradeToExtendedOptimismMintableToken_sucess() external {
        upgraderImpl.run();

        // Proxy assertions
        vm.prank(address(0));
        assertEq(ExtendedOptimismMintableTokenProxy.implementation(), address(L2TokenImpl));
        vm.prank(address(0));
        assertEq(ExtendedOptimismMintableTokenProxy.admin(), admin);
        
        // ExtendedOptimismMintableToken assertions
        assertEq(L2Token.BRIDGE(), L2Token.BRIDGE());
        assertEq(L2Token.REMOTE_TOKEN(), L2Token.REMOTE_TOKEN());
        assertEq(L2Token.decimals(), L2Token.decimals());
        assertEq(L2Token.name(), string(abi.encodePacked("L2-", L1Token.name())));
        assertEq(L2Token.symbol(), string(abi.encodePacked("L2-", L1Token.symbol())));
        assertTrue(L2Token.hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertTrue(L2Token.hasRole(PAUSER_ROLE, pauser));
        assertTrue(L2Token.hasRole(BLACKLISTER_ROLE, blacklister));   
        assertFalse(L2Token.paused());
    }
}
